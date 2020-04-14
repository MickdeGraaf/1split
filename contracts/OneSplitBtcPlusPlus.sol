pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./OneSplitBase.sol";
import "./interface/IBtcPlusPlus.sol";
import "./interface/IBPool.sol";


contract OneSplitBtcPlusPlusBase {
    IBtcPlusPlusExchange btcPlusPlusExchange = IBtcPlusPlusExchange(0x17EBe8E4FCa93A973f98f93708b0dFc142c45De9);
    IERC20 btcPlusPlus = IERC20(0x0327112423F3A68efdF1fcF402F6c5CB9f7C33fd);
    IBPool btcPlusPlusBalancerPool = IBPool(0x9891832633a83634765952b051bc7feF36714A46);

    function _isBtcPlusPlusToken(IERC20 token) internal view returns (bool) {
        address[] memory tokens = btcPlusPlusBalancerPool.getCurrentTokens();

        for (uint256 i = 0; i < tokens.length; i++) {
            if (IERC20(tokens[i]) == token) {
                return true;
            }
        }

        return false;
    }
}


contract OneSplitBtcPlusPlusView is OneSplitBtcPlusPlusBase, OneSplitBaseView{

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        internal
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }

        if (!disableFlags.check(FLAG_DISABLE_BTCPP)) {
            // if swapping from BTC++ to one of the underlying
            if (fromToken == btcPlusPlus) {
                // If converting BTC++ token
                if (_isBtcPlusPlusToken(toToken)) {
                    // TODO distribution
                    distribution = new uint256[](10);
                    returnAmount = btcPlusPlusExchange.calcSingleOutGivenPoolIn(address(toToken), amount);
                    return(returnAmount, distribution);
                } else {
                    distribution = new uint256[](10);
                    // Default to first token in pool (WBTC)
                    IERC20 betweenToken = IERC20(btcPlusPlusBalancerPool.getCurrentTokens()[0]);
                    returnAmount = btcPlusPlusExchange.calcSingleOutGivenPoolIn(address(betweenToken), amount);
                    return super.getExpectedReturn(
                        betweenToken,
                        toToken,
                        returnAmount,
                        parts,
                        disableFlags
                    );
                }
            }
            // else if swapping from one of the underlying to BTC++
            else if (toToken == btcPlusPlus) {

                if (_isBtcPlusPlusToken(fromToken)) {
                    // if converting from one of the underlying assets
                    distribution = new uint256[](10);
                    returnAmount = btcPlusPlusExchange.calcPoolOutGivenSingleIn(address(fromToken), amount);
                    return(returnAmount, distribution);
                } else {
                    // if not get price to convert from toToken to WBTC to BTC++
                    IERC20 betweenToken = IERC20(btcPlusPlusBalancerPool.getCurrentTokens()[0]);
                    (returnAmount, distribution) = super.getExpectedReturn(
                        fromToken,
                        betweenToken,
                        amount,
                        parts,
                        disableFlags
                    );

                    returnAmount = btcPlusPlusExchange.calcPoolOutGivenSingleIn(address(betweenToken), returnAmount);
                    return(returnAmount, distribution);
                }

            }
        }

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }
}


contract OneSplitBtcPlusPlus is OneSplitBtcPlusPlusBase, OneSplitBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        if (!disableFlags.check(FLAG_DISABLE_BTCPP)) {
            // if swapping from BTC++ to one of the underlying
            if (fromToken == btcPlusPlus) {
                _infiniteApproveIfNeeded(btcPlusPlus, address(btcPlusPlusExchange));
                // If swapping to one of the underlying assets
                if (_isBtcPlusPlusToken(toToken)) {
                    btcPlusPlusExchange.exitswapPoolAmountIn(address(toToken), amount, 1);
                    return;
                } else {
                    // Swap to WBTC by default
                    IERC20 betweenToken = IERC20(btcPlusPlusBalancerPool.getCurrentTokens()[0]);
                    btcPlusPlusExchange.exitswapPoolAmountIn(address(betweenToken), amount, 1);

                    return super._swap(betweenToken, toToken, btcPlusPlus.balanceOf(address(this)), distribution, disableFlags);
                }
            }
            // else if swapping from one of the underlying to BTC++
            else if (toToken == btcPlusPlus) {
                // if swapping from one of the underlying assets
                if (_isBtcPlusPlusToken(fromToken)) {
                    _infiniteApproveIfNeeded(fromToken, address(btcPlusPlusExchange));
                    btcPlusPlusExchange.joinswapExternAmountIn(address(fromToken), amount, 1);
                    return;
                } else {
                    //Swap to WBTC first
                    IERC20 betweenToken = IERC20(btcPlusPlusBalancerPool.getCurrentTokens()[0]);
                    super._swap(fromToken, betweenToken, amount, distribution, disableFlags);
                    _infiniteApproveIfNeeded(betweenToken, address(btcPlusPlusExchange));
                    btcPlusPlusExchange.joinswapExternAmountIn(address(betweenToken), betweenToken.balanceOf(address(this)), 1);
                    return;
                }
            }
        }

        return super._swap(fromToken, toToken, amount, distribution, disableFlags);
    }
}
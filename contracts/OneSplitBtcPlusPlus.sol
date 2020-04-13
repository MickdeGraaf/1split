pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./OneSplitBase.sol";
import "../interface/IBtcPlusPlus.sol";
import "../interface/IBPool.sol";


contract OneSplitBtcPlusPlusBase {
    IBtcPlusPlusExchange btcPlusPlusExchange = IBtcPlusPlusIBtcPlusPlusExchange(0x17EBe8E4FCa93A973f98f93708b0dFc142c45De9);
    IERC20 btcPlusPlus = IERC20(0x0327112423f3a68efdf1fcf402f6c5cb9f7c33fd);
    IBPool btcPlusPlusBalancerPool = IBPool(0x9891832633a83634765952b051bc7fef36714a46);

    function _isBtcPlusPlusToken(IERC20(token)) internal returns (bool) {
        adddress[] memory tokens = btcPlusPlusBalancerPool.getCurrentTokens();

        for(uint256 i = 0; i < tokens.tokens.length; i++) {
            if(IERC20(tokens[i]) == token) {
                return true;
            }
        }

        return false;
    }
}


contract OneSplitBtcPlusPlusView is OneSplitBtcPlusPlusBase{

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        public
        view
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
            if (fromToken == btcPlusPlus && _isBtcPlusPlusToken(toToken)) {
                return super.getExpectedReturn(
                    dai,
                    toToken,
                    amount,
                    parts,
                    disableFlags
                );
            }
            // else if swapping from one of the underlying to BTC++
            else if (_isBtcPlusPlusToken(fromToken) && toToken == btcPlusPlus) {
                return super.getExpectedReturn(
                    fromToken,
                    dai,
                    amount,
                    parts,
                    disableFlags
                );
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


contract OneSplitBtsPlusPlus {
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
    }
}
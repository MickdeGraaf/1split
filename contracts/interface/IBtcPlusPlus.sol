pragma solidity ^0.5.0;

interface IBtcPlusPlusExchange {
    function joinswapExternAmountIn(address tokenIn, uint256 tokenAmountIn, uint256 minPoolAmountOut) external returns(uint256);
    function exitswapPoolAmountIn(address tokenOut, uint256 poolAmountIn, uint256 minAmountOut) external returns(uint256);
    function calcSingleOutGivenPoolIn(address tokenOut, uint256 poolIn) external view returns(uint256);
    function calcPoolOutGivenSingleIn(address tokenIn, uint256 tokenAmountIn) external view returns(uint256);
}
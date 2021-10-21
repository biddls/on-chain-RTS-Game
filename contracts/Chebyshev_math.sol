//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library Chebyshev_math {
    function distance(uint256 x1, uint256 y1, uint256 x2, uint256 y2) public pure returns(uint256){
        return _max(_diff(x1, x2), _diff(y1, y2));
    }
    function _diff(uint256 a, uint256 b) internal pure returns(uint256){
        return (_max(a, b) - _min(a, b));
    }
    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function _underflowSub(uint256 a, uint256 b) internal pure returns (uint256){
        return a < b ? (((2 ^ 256) -1 ) -b) : (a - b);
    }
}

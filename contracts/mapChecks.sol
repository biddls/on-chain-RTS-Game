//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library mapChecks {

    function _isStart(
        uint256 _x,
        uint256 _y,
        uint256 _x1Removed,
        uint256 _y1Removed,
        uint256 _x2Start,
        uint256 _y2Start)
    internal pure returns (bool) {
        return (((_x2Start) - (_x1Removed - 1) == _x) && ((_y2Start) - (_y1Removed - 1) == _y));
    }
}

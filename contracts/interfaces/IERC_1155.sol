//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC_1155{
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

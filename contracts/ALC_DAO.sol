//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract ALC_DAO is ERC1155PresetMinterPauser{
    constructor () ERC1155PresetMinterPauser(""){
    }
}
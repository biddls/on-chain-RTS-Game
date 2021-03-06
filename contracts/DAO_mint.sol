//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./interfaces/IERC_1155.sol";

contract DAO_mint {
//    IERC_1155 public DAO_NFTS;
    address public DAO_NFTS_addr;
    uint256 public max_amount = 10;
    uint256 public max_id = 4;
    mapping(address => uint256) public max_NFT;
    address public admin;

    constructor (){
        admin = msg.sender;
    }

    function getNFTs(uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external {
        require(_ids.length == _amounts.length, "not equal length");
        require(_amounts.length <= 5, "max id number is 4");
        uint256 _sum;
        for(uint8 i=0;i<_amounts.length;i++){
            _sum += _amounts[i];
            require(_ids[i] <= max_id);
        }
        require((_sum + max_NFT[msg.sender]) <= 10);
        IERC_1155(DAO_NFTS_addr).mintBatch(msg.sender, _ids, _amounts, _data);
        max_NFT[msg.sender] += _sum;
    }

    function changeDAOAddr(address _to) external {
        require(msg.sender == admin);
        require(_to != address(0));
        DAO_NFTS_addr = _to;
    }
}

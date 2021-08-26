//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IALCX_map {
    function deadTiles () external returns (uint256);

    struct tile {
        address keeper;
        uint256 ALCX_DAO_NFT_ID;
        uint256 index;
        bool dead;
    }

    function nextX () external returns (uint256);
    function nextY () external returns (uint256);
    function radius () external returns (uint256);

    // map functions
    // allows people to send in their NFTs for land
    // this action is none revertible
    function redeemNFTsForLand(uint256[] memory _ids, uint256[] memory _amounts) external;
    // magic functions
    // reinforces land by staking NFTs to protect it
    function increaseLandsProtection(uint256 _x, uint256 _y, uint256 _amount) external;

    // removes NFTs from land
    function decreaseLandsProtection(uint256 _x, uint256 _y, uint256 _amount) external;

    // uses the NFTs to attack a tile
    function magicAttack(uint256 _attackX, uint256 _attackY, uint256 _fromX, uint256 _fromY, uint256 _amount) external;
}

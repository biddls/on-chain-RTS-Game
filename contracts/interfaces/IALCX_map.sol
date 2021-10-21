//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface IALCX_map {
    // game functions
    function redeemNFTsForLand ( uint256[] memory _ids, uint256[] memory _amounts) external;
    function decreaseLandsProtection ( uint256 _x, uint256 _y, uint256 _amount) external;
    function increaseLandsProtection ( uint256 _x, uint256 _y, uint256 _amount) external;
    function magicAttack ( uint256 _attackX, uint256 _attackY, uint256 _fromX, uint256 _fromY, uint256 _amount) external;

    // nft
    function batchedFromToDAONFT(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory _data) external;    // abstraction function to move a dao NFT
    function fromToDAONFT(address from, address to, uint256 id, uint256 amount, bytes memory _data) external;

    // restricited mapping changes
    function mapContExternal_ALCX_DAO_NFT_ID_change(uint256 _x, uint256 _y, bool _add, uint256 _amount) external;
    function mapContExternal_index_change(uint256 _x, uint256 _y, bool _add, uint256 _amount) external;
    function mapContExternal_dead_change(uint256 _x, uint256 _y, bool _alive) external;
    function mapContExternal_NFTProtection_change(uint256 _x, uint256 _y, bool _add, uint256 _amount) external;
    function killTile(uint256 _x, uint256 _y) external;

    //look ups
    struct Tile {
        uint256 ALCX_DAO_NFT_ID;
        uint256 index;
        bool dead;
        uint256 NFTProtection;
        uint256 lastChange;
    }
    function map (uint256, uint256) external view returns ( Tile memory tile);
    function mapContExternal_ALCX_DAO_NFT_ID(uint256 _x, uint256 _y) external view returns (uint256);
    function mapContExternal_index(uint256 _x, uint256 _y) external view returns (uint256);
    function mapContExternal_dead(uint256 _x, uint256 _y) external view returns (bool);
    function mapContExternal_NFTProtection(uint256 _x, uint256 _y) external view returns (uint256);
    function IDtoXY ( uint256, uint256) external view returns ( uint256); // idk about this one seems kinda sus
    function distance(uint256 x1, uint256 y1, uint256 x2, uint256 y2) external pure returns(uint256);
    function mapStaysWhole(uint256 _x1Removed, uint256 _y1Removed, uint256 _x2Start, uint256 _y2Start) external view returns (bool);

    // other lookups
    function nextX ( ) external view returns ( uint256);
    function nextY ( ) external view returns ( uint256);
    function radius ( ) external view returns ( uint256);
    function deadTiles ( ) external view returns ( uint256);

    // dev lookups
    function mapNFTs ( ) external view returns ( address);
    function mapNFTAddr ( ) external view returns ( address);
    function mapNFTsAddr ( ) external view returns ( address);
    function DAO_nft_Token ( ) external view returns ( address);
    function admin ( ) external view returns ( address);

    // dev functions
    function adminChange ( address _to) external;
    function DAO_nft_TokenChange ( address _to) external;
}

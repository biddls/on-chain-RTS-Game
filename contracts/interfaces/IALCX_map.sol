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

    function redeemNFTsForLand(uint256[] memory _ids, uint256[] memory _amounts) external;
}

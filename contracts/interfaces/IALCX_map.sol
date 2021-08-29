//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface IALCX_map {
    // game functions
    function redeemNFTsForLand ( uint256[] memory _ids, uint256[] memory _amounts ) external;
    function decreaseLandsProtection ( uint256 _x, uint256 _y, uint256 _amount ) external;
    function increaseLandsProtection ( uint256 _x, uint256 _y, uint256 _amount ) external;
    function magicAttack ( uint256 _attackX, uint256 _attackY, uint256 _fromX, uint256 _fromY, uint256 _amount ) external;

    //look ups
    function map ( uint256, uint256 ) external view returns ( uint256 ALCX_DAO_NFT_ID, uint256 index, bool dead, uint256 NFTProtection );
    function IDtoXY ( uint256, uint256 ) external view returns ( uint256 ); // idk about this one seems kinda sus

    // other lookups
    function nextX (  ) external view returns ( uint256 );
    function nextY (  ) external view returns ( uint256 );
    function radius (  ) external view returns ( uint256 );
    function deadTiles (  ) external view returns ( uint256 );

    // dev lookups
    function mapNFTs (  ) external view returns ( address );
    function mapNFTAddr (  ) external view returns ( address );
    function mapNFTsAddr (  ) external view returns ( address );
    function DAO_nft_Token (  ) external view returns ( address );
    function admin (  ) external view returns ( address );

    // dev functions
    function adminChange ( address _to ) external;
    function DAO_nft_TokenChange ( address _to ) external;
}

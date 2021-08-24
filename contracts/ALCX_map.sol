pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";


contract ALCX_map is ERC721PresetMinterPauserAutoId{
    // tile / map admin stuff
    // amount of dead tiles
    uint256 public deadTiles;

    // struct that holds basic info about a tile
    struct tile {
        address keeper;
        uint256 ALCX_DAO_NFT_ID;
        uint256 index;
        bool dead;
        uint256 NFTProtection;
    }

    // data that is used to run the map generation / data lookup
    mapping(uint256 => mapping(uint256 => tile)) public map;
    mapping(uint256 => uint256[2]) public IDtoXY;
    uint256 public nextX = 0;
    uint256 public nextY = 0;
    uint256 public radius = 1;

    //admin stuff
    address public DAO_nft_Token;

    constructor() ERC721PresetMinterPauserAutoId("Alchemix DAOs map", "ALC MAP", ""){
        _addLand(msg.sender, 2**256 -1);
    }

    // map functions
    // allows people to send in their NFTs for land
    // this action is none revertible
    function redeemNFTsForLand(uint256[] memory _ids, uint256[] memory _amounts) external {
        require(_ids.length > 0, "cant pass an empty array");

        batchedFromToDAONFT(msg.sender, address(this), _ids, _amounts, "");

        for (uint256 i=0; i<_ids.length; i++) {
            // check that it transferred
            for (uint256 a=0; a<_amounts[i]; a++) {
                _addLand(msg.sender, _ids[i]);
            }
        }
    }

    /* generates land from the bottom left up and to the right in concentric rings:
    |8|7|6|
    |3|2|5|
    |0|1|4|
    */
    function _addLand(address _for, uint256 _id) internal {
        map[nextX][nextY] = tile(_for, _id, totalSupply(), false, 0);
        IDtoXY[totalSupply()] = [nextX, nextY];
        if(nextX == 0){
            nextX = radius;
            nextY = 0;
            radius++;
        } else if (nextY < radius - 1){
            nextY++;
        } else {
            nextX--;
        }
        mint(_for);
    }

    // marks a tile as dead the NFT owner can still hold onto the now useless tile
    function _killTile(uint256 _x, uint256 _y) internal {
        map[_x][_y].dead = true;
        deadTiles++;
        burn(map[_x][_y].index);
    }

    // moves a tile from one user to another
    function _transferTile(address _to, uint256 _x, uint256 _y) internal {
        require(_to != address(0), "cant send to 0 address");
        require(map[_x][_y].keeper == msg.sender);
        map[_x][_y].keeper = _to;
    }

    // admin
    function batchedFromToDAONFT(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal {
        (bool success) =
        address(DAO_nft_Token).call(
            abi.encodePacked(
                IERC1155.safeBatchTransferFrom.selector,
                abi.encode(from, to, ids, amounts, data)));

        require(success, "Transfer of NFTs not successful");
    }

    function fromToDAONFT(address from, address to, uint256 id, uint256 amount, bytes memory data) internal {
        (bool success) =
        address(DAO_nft_Token).call(
            abi.encodePacked(
                IERC1155.safeTransferFrom.selector,
                abi.encode(from, to, id, amount, data)));

        require(success, "Transfer of NFTs not successful");
    }

    // magic functions
    // reinforces land by staking NFTs to protect it
    function increaseLandsProtection(uint256 _x, uint256 _y, uint256 _amount) external {
        require(_amount != 0, "can't send 0 NFTs");
        require(map[_x][_y].keeper == msg.sender, "address doesn't own account");

        fromToDAONFT(msg.sender, address(this), map[_x][_y].ALCX_DAO_NFT_ID, _amount, "");

        map[_x][_y].NFTProtection += _amount;
    }

    // removes NFTs from land
    function decreaseLandsProtection(uint256 _x, uint256 _y, uint256 _amount) external {
        require(_amount != 0, "can't send 0 NFTs");
        require(map[_x][_y].keeper == msg.sender, "address doesn't own account");
        require(map[_x][_y].NFTProtection >= _amount, "Not enough NFTs on tile");

        fromToDAONFT(address(this), msg.sender, map[_x][_y].ALCX_DAO_NFT_ID, _amount, "");

        map[_x][_y].NFTProtection -= _amount;
    }

    function magicAttack(uint256 _attackX, uint256 _attackY, uint256 _fromX, uint256 _fromY, uint256 _amount) external {
//        make sure that defending land boarders the attackers land
        require(_attackX != _fromX && _attackY == _fromY, "cant attack your self");
        require(_distance(_attackX, _attackY, _fromX, _fromY) == 1, "Too far away");

        // add checks here to make sure the whole map stays connected
        require(_mapStaysWhole, "Cant destroy that as it would separate the map");

        // make sure that attacker has enough NFTs
        fromToDAONFT(msg.sender, address(this), map[_attackX][_attackY].ALCX_DAO_NFT_ID, _amount, "");
        // see who wins
        // if defender wins subtract protection from attackers force
        if(_amount > map[_attackX][_attackY].NFTProtection) {
            // burn all attackers NFTs
            // burn defenders - attacks NFTs
            /*
            map[_attackX][_attackY].NFTProtection  * 2
            this is because we burn all of the defenders and the same amount from the attacker
            so just simplify it down to 2 lots the min amount because both sides loose
            */
            // change this to burn eventually
            fromToDAONFT(address(this), address(1),
                map[_attackX][_attackY].ALCX_DAO_NFT_ID,
                map[_attackX][_attackY].NFTProtection * 2, "");
        } // if defender looses destroy land and everything on it
        else {
            // burn all defenders NFTs
            // burn attacks - defenders NFTs
            // see simplification math above ^^

            // kill the land
            fromToDAONFT(address(this), address(1),
                map[_attackX][_attackY].ALCX_DAO_NFT_ID,
                _amount * 2, "");

            _killTile(_attackX, _attackY);
        }
    }

    function _mapStaysWhole(uint256 _x, uint256 _y) internal pure returns(bool){
        // no clue how ima do this
        return true;
    }

    // Chebyshev distance
    function _distance(uint256 x1, uint256 x2, uint256 y1, uint256 y2) internal pure returns(uint256){
        return _max(_diff(x1, x2), _diff(y1, y2));
    }

    // |a-b|
    function _diff(uint256 a, uint256 b) internal pure returns(uint256){
        return _max(a, b) - _min(a, b);
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
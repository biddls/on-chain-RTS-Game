//SPDX-License-Identifier: UNLICENSED
// https://ethereum.stackexchange.com/questions/72687/explanation-of-appending-selector-in-solidity-smart-contracts/72690
pragma solidity ^0.8.0;

import {ERC721PresetMinterPauserAutoId} from "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import {ERC1155PresetMinterPauser} from "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {Chebyshev_math} from "./Chebyshev_math.sol";
import {mapChecks} from "./mapChecks.sol";

contract ALCX_map is ERC1155Holder, AccessControlEnumerable{
    ERC721PresetMinterPauserAutoId public mapNFTs =
    new ERC721PresetMinterPauserAutoId(
        "Alchemix DAOs map", "ALC MAP", "");
    address public mapNFTAddr = address(mapNFTs);

    // struct that holds basic info about a tile
    struct Tile {
        uint256 ALCX_DAO_NFT_ID;
        uint256 index;
        bool dead;
        uint256 NFTProtection;
        uint256 lastChange;
    }

    // time delay
    uint256 delay = 86400;

    // data that is used to run the map generation / data lookup
    // x -> y -> tile
    mapping(uint256 => mapping(uint256 => Tile)) public map;
    mapping(uint256 => uint256[2]) public IDtoXY;
    uint256 public nextX = 0;
    uint256 public nextY = 0;
    uint256 public radius = 1;

    // tile / map admin stuff
    // amount of dead tiles
    uint256 public deadTiles;

    //admin stuff
    ERC1155PresetMinterPauser internal alcDaoNFT;
    address public DAO_nft_Token;

    // roles
    bytes32 public constant MAP_CONTROL = keccak256("MAP_CONTROLLER");

    // local var mapping
//    mapping(uint8 => bool) private _numberLookup;

    constructor() {
        _addLand(msg.sender, 2**256 -1);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // map functions
    // allows people to send in their NFTs for land
    // this action is none revertible
    function redeemNFTsForLand(uint256[] memory _ids, uint256[] memory _amounts) external {

        require(_ids.length > 0, "cant pass an empty array");

        _batchedFromToDAONFT(msg.sender, address(this), _ids, _amounts, "");

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
        // spawns the live tile
        map[nextX][nextY] = Tile(_id, mapNFTs.totalSupply(), false, 0, block.timestamp - 86400);
        // fills in the ID to XY look up mapping
        IDtoXY[mapNFTs.totalSupply()] = [nextX, nextY];
        // if directly in line with the 0,0 block
        if(nextX == 0){
            // move to (radius,0)
            nextX = radius;
            nextY = 0;
            radius++;
            // if y is lower than radius increase along the vertical column
        } else if (nextY < radius - 1){
            nextY++;
            // if y is on the radius then move to the right
        } else {
            nextX--;
        }
        // create a land tile ERC-721 NFT
        mapNFTs.mint(_for);
    }

    // marks a tile as dead the NFT owner can still hold onto the now useless tile
    function killTile(uint256 _x, uint256 _y) external {
        require(hasRole(MAP_CONTROL, msg.sender));
        _killTile(_x, _y);
    }
    function _killTile(uint256 _x, uint256 _y) internal {
        // toggles the bool variable
        map[_x][_y].dead = true;
        // increases the count of dead tiles
        deadTiles++;
    }

    // admin
    // abstraction function to move the dao NFTs
    function batchedFromToDAONFT(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory _data) public {
        require(hasRole(MAP_CONTROL, msg.sender));
        _batchedFromToDAONFT(from, to, ids, amounts, _data);
    }
    function _batchedFromToDAONFT(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory _data) internal {
        alcDaoNFT.safeBatchTransferFrom(from, to, ids, amounts, _data);
    }
    // abstraction function to move a dao NFT
    function fromToDAONFT(address from, address to, uint256 id, uint256 amount, bytes memory _data) public {
        require(hasRole(MAP_CONTROL, msg.sender));
        _fromToDAONFT(from, to, id, amount, _data);
    }
    function _fromToDAONFT(address from, address to, uint256 id, uint256 amount, bytes memory _data) internal {
        alcDaoNFT.safeTransferFrom(from, to, id, amount, _data);
    }

    // checks
    function mapStaysWhole(
        uint256 _x1Removed,
        uint256 _y1Removed,
        uint256 _x2Start,
        uint256 _y2Start
    ) external view returns (bool) {
        return _mapStaysWhole(_x1Removed, _y1Removed, _x2Start, _y2Start);
    }

    function _mapStaysWhole(
        uint256 _x1Removed,
        uint256 _y1Removed,
        uint256 _x2Start,
        uint256 _y2Start
    ) internal view returns (bool) {
        // generates dead map and list of live tiles
        //both tiles are alive
        require(!map[_x1Removed][_y1Removed].dead && !map[_x2Start][_y2Start].dead, "both tiles must be aliive");
        // false is dead
        bool[3][3] memory _tempMap;
        // instead of X,Y use a number (0-8) anti-clockwise spiraling in from 0,0 to 1,1 see `spots`
        _tempMap[1][1] = true;
        uint8 [2][8] memory spots = [[0, 0], [1, 0], [2, 0], [2, 1], [2, 2], [1, 2], [0, 2], [0, 1]];
        uint8 _startNumb;
        uint8 _alive;
        bool[9] memory _numberLookup;
        // converts the soon to die square to the center of a 3X3 array
        for(uint8 i=0; i<spots.length; i++){
            // cleaning the previous _numberLookup
            _numberLookup[i] = false;
            // anything that falls off the edge gets looped around to a max int position
            // that would need 2^(255*2) NFTs to be withdrawn to get to
            // so now its querying a dead tile that wont ever reasonably get reached
            uint256 _shiftedX = Chebyshev_math._underflowSub(_x1Removed, spots[i][0]);
            uint256 _shiftedY = Chebyshev_math._underflowSub(_y1Removed, spots[i][1]);

            // if the tile it looks at is dead it adds it to the list
            // and then goes to the next tile in `spots`
            if(!map[_shiftedX][_shiftedY].dead){continue;}

            // if it passes all of that its now true
            _tempMap[spots[i][0]][spots[i][1]] = true;
            // fills in number mapping
            _numberLookup[i] = true;
            // counts number of alive tiles it sees
            _alive++;

            if(mapChecks._isStart(spots[i][0], spots[i][1], _x1Removed, _y1Removed, _x2Start, _y2Start)){
                _startNumb = i;
            }
        }
        // if only 2 are dead the 3X3 can still be fully traversed
        if(_alive > 6){return true;}
        if(_alive == 1){return true;}

        /* linked list of numbers to visit (anti-)clockwise around the 1,1 square
        the logic follows that if ew can start from the attacking square (which we know is alive)
        then we can either search left or right around the dead center square
        and if we dont reach all of the alive squares then going through the dead center square
        must be the only option to get to them thus it can be destroyed
        data is stored for the graph like 0:[1,8] but we can remove 0 and just use its index boi
        */
        uint8 [2][8] memory _transitions = [[1, 8], [2, 3], [3, 8], [4, 5], [5, 8], [6, 7], [7, 8], [0, 1]];
        uint8 [2][8] memory _transitionsClock = [[7, 8], [0, 7], [1, 8], [2, 1], [3, 8], [4, 3], [5, 8], [0, 1]];

        // both on the anti-clockwise side are dead look clockwise
        if(!_numberLookup[_transitionsClock[_startNumb][0]] && !_numberLookup[_transitionsClock[_startNumb][1]]){
            _transitions = _transitionsClock;
        }

        // keeps track to make sure that we have seen all the points we need to
        uint8 _visited = 1;
        // not needed could just use _startNumb but makes it easier to look through
        uint8 _nextNumb = _startNumb;
        // holds the pair of data for it to look through
        uint8 _temp0;
        uint8 _temp1;
        for(uint8 i=0;i<_alive; i++){
            _temp0 = _transitions[_nextNumb][0];
            _temp1 = _transitions[_nextNumb][1];
            if(_numberLookup[_temp0]){ //chooses to look at closes number first (not diagonal)
                _nextNumb = _temp0;
                _visited++;
            } else if (_numberLookup[_temp1]){ // then looks at diagonal
                // (or the center one as it had to fill out the array)
                _nextNumb = _temp1;
                _visited++;
            } else {
                return false;
            }
        }
        return true;
    }

    // admin
    function DAO_nft_TokenChange(address _to) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        require(_to != address(0));
        DAO_nft_Token = _to;
        alcDaoNFT = ERC1155PresetMinterPauser(DAO_nft_Token);
    }
    function adminChange(address _to) external {
        require(_to != address(0));
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        grantRole(DEFAULT_ADMIN_ROLE, _to);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    function changeDelay(uint256 _delay) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        delay = _delay;
    }
    function mapNFTsAddr() external view returns (address) {
        return address(mapNFTs);
    }
    function map_control_roll_control(bool _add, address _to) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        require(_to != address(0));
        if(_add) {
            grantRole(MAP_CONTROL, _to);
        } else {
            revokeRole(MAP_CONTROL, _to);
        }
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(
    AccessControlEnumerable, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // mapping
    // reading values
    function mapContExternal_ALCX_DAO_NFT_ID(uint256 _x, uint256 _y) external view returns (uint256){
        return (map[_x][_y].ALCX_DAO_NFT_ID);
    }
    function mapContExternal_index(uint256 _x, uint256 _y) external view returns (uint256){
        return (map[_x][_y].index);
    }
    function mapContExternal_dead(uint256 _x, uint256 _y) external view returns (bool){
        return (map[_x][_y].dead);
    }
    function mapContExternal_NFTProtection(uint256 _x, uint256 _y) external view returns (uint256){
        return (map[_x][_y].NFTProtection);
    }
    function mapContExternal_lastChange(uint256 _x, uint256 _y) external view returns (uint256){
        return (map[_x][_y].lastChange);
    }
    // writing values
    function mapContExternal_ALCX_DAO_NFT_ID_change(uint256 _x, uint256 _y, bool _add, uint256 _amount) external{
        require(hasRole(MAP_CONTROL, msg.sender));
        if(_add){
            map[_x][_y].ALCX_DAO_NFT_ID += _amount;
        } else {
            require(map[_x][_y].ALCX_DAO_NFT_ID >= _amount);
            map[_x][_y].ALCX_DAO_NFT_ID -= _amount;
        }
    }
    function mapContExternal_dead_change(uint256 _x, uint256 _y, bool _alive) external{
        require(hasRole(MAP_CONTROL, msg.sender));
        map[_x][_y].dead = _alive;
    }
    function mapContExternal_NFTProtection_change(uint256 _x, uint256 _y, bool _add, uint256 _amount) external{
        require(hasRole(MAP_CONTROL, msg.sender));
        if(_add){
            map[_x][_y].NFTProtection += _amount;
        } else {
            require(map[_x][_y].NFTProtection >= _amount);
            map[_x][_y].NFTProtection -= _amount;
        }
    }
    function mapContExternal_lastChange(uint256 _x, uint256 _y, uint256 _amount) external{
        require(hasRole(MAP_CONTROL, msg.sender));
        map[_x][_y].lastChange = _amount;
    }
}
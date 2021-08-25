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
        uint256 ALCX_DAO_NFT_ID;
        uint256 index;
        bool dead;
        uint256 NFTProtection;
    }

    // data that is used to run the map generation / data lookup
    // x -> y -> tile
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
        map[nextX][nextY] = tile(_id, totalSupply(), false, 0);
        // fills in the ID to XY look up mapping
        IDtoXY[totalSupply()] = [nextX, nextY];
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
        mint(_for);
    }

    // marks a tile as dead the NFT owner can still hold onto the now useless tile
    function _killTile(uint256 _x, uint256 _y) internal {
        // toggles the bool variable
        map[_x][_y].dead = true;
        // increases the count of dead tiles
        deadTiles++;
    }

    // admin
    // abstraction function to move the dao NFTs
    function _batchedFromToDAONFT(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal {
        (bool success) =
        address(DAO_nft_Token).call(
            abi.encodePacked(
                IERC1155.safeBatchTransferFrom.selector,
                abi.encode(from, to, ids, amounts, data)));

        require(success, "Transfer of NFTs not successful");
    }

    // abstraction function to move a dao NFT
    function _fromToDAONFT(address from, address to, uint256 id, uint256 amount, bytes memory data) internal {
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
        require(ownerOf(map[_x][_y].index) == msg.sender, "address doesn't own account");

        _fromToDAONFT(msg.sender, address(this), map[_x][_y].ALCX_DAO_NFT_ID, _amount, "");

        map[_x][_y].NFTProtection += _amount;
    }

    // removes NFTs from land
    function decreaseLandsProtection(uint256 _x, uint256 _y, uint256 _amount) external {
        require(_amount != 0, "can't send 0 NFTs");
        require(ownerOf(map[_x][_y].index) == msg.sender, "address doesn't own account");
        require(map[_x][_y].NFTProtection >= _amount, "Not enough NFTs on tile");

        _fromToDAONFT(address(this), msg.sender, map[_x][_y].ALCX_DAO_NFT_ID, _amount, "");

        map[_x][_y].NFTProtection -= _amount;
    }

    function magicAttack(uint256 _attackX, uint256 _attackY, uint256 _fromX, uint256 _fromY, uint256 _amount) external {
//        make sure that defending land boarders the attackers land
        require(_attackX != _fromX && _attackY == _fromY, "cant attack your self");
        require(_distance(_attackX, _attackY, _fromX, _fromY) == 1, "Too far away");

        // add checks here to make sure the whole map stays connected
        require(_mapStaysWhole(_attackX, _attackY, _fromX, _fromY), "Cant destroy that as it would separate the map");

        // make sure that attacker has enough NFTs
        _fromToDAONFT(msg.sender, address(this), map[_attackX][_attackY].ALCX_DAO_NFT_ID, _amount, "");
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
            _fromToDAONFT(address(this), address(1),
                map[_attackX][_attackY].ALCX_DAO_NFT_ID,
                map[_attackX][_attackY].NFTProtection * 2, "");
        } // if defender looses destroy land and everything on it
        else {
            // burn all defenders NFTs
            // burn attacks - defenders NFTs
            // see simplification math above ^^
            _fromToDAONFT(address(this), address(1),
                map[_attackX][_attackY].ALCX_DAO_NFT_ID,
                _amount * 2, "");

            // kill the land
            require(_mapStaysWhole(_attackX, _attackY, _fromX, _fromY));
            _killTile(_attackX, _attackY);
        }
    }

    function _mapStaysWhole(
        uint256 _x1Removed,
        uint256 _y1Removed,
        uint256 _x2Start,
        uint256 _y2Start)
    internal pure returns
    (bool) {
        // generates dead map and list of live tiles
        //both tiles are alive
        require(!map[_x1Removed][_y1Removed].dead && !map[_x2Start][_y2Start].dead);
        // false is dead
        bool[3][3] _tempMap;
        // instead of X,Y use a number (0-8) anti-clockwise spiraling in from 0,0 to 1,1 see `spots`
        mapping(uint => bool) _numberLookup;
        _tempMap[1][1] = true;
        uint [8][2] spots = [[0, 0], [1, 0], [2, 0], [2, 1], [2, 2], [1, 2], [0, 2], [0, 1]];
        uint _startNumb;
        uint _alive;
        // converts the soon to die square to the center of a 3X3 array
        for(i=0; i<spots.length; i++){
            // anything that falls off the edge gets looped around to a max int position
            // that would need 2^(255*2) NFTs to be withdrawn to get to
            // so now its querying a dead tile that wont ever reasonably get reached
            uint256 _shiftedX = _underflowSub(_x1Removed, spots[i][0]);
            uint256 _shiftedY = _underflowSub(_y1Removed, spots[i][1]);

            // if the tile it looks at is dead it adds it to the list
            // and then goes to the next tile in `spots`
            if(!map[_shiftedX][_shiftedY].dead){dead++; continue;}

            // if it passes all of that its now true
            _tempMap[spots[i][0]][spots[i][1]] = true;
            // fills in number mapping
            _numberLookup[i] = true;
            // counts number of alive tiles it sees
            _alive++;

            if(_isStart(spots[i][0], spots[i][1], _x1Removed, _y1Removed, _x2Start, _y2Start)){
                _startNumb = i;
            }
        }
        // if only 2 are dead the 3X3 can still be fully traversed
        if(_alive > 6){return (true);}
        if(_alive == 1){return (true);}

        // linked list of numbers to visit (anti-)clockwise around the 1,1 square
        // the logic follows that if ew can start from the attacking square (which we know is alive)
        // then we can either search left or right around the dead center square
        // and if we dont reach all of the alive squares then going through the dead center square
        // must be the only option to get to them thus it can be destroyed
        // data is stored for the graph like 0:[1,8] but we can remove 0 and just use its index boi
        uint [8][2] _transitions = [[1, 8], [2, 3], [3, 8], [4, 5], [5, 8], [6, 7], [7, 8], [0, 1]];
        uint [8][2] _transitionsClock = [[7, 8], [0, 7], [1, 8], [2, 1], [3, 8], [4, 3], [5, 8], [0, 1]];

        // both on the anti-clockwise side are dead look clockwise
        if(!_numberLookup[_transitionsClock[_startNumb][0]] && !_numberLookup[_transitionsClock[_startNumb][1]]){
            _transitions = _transitionsClock;
        }

        // keeps track to make sure that we have seen all the points we need to
        uint _visited = 1;
        // not needed could just use _startNumb but makes it easier to look through
        uint _nextNumb = _startNumb;
        // holds the pair of data for it to look through
        uint[2] _temp;
        for(i=0;i<_alive; i++){
            _temp = _transitions[_nextNumb];
            if(_numberLookup(_temp[0])){ //chooses to look at closes number first (not diagonal)
                _nextNumb = _temp[0];
                _visited++;
            } else if (_numberLookup(_temp[1])){ // then looks at diagonal
                // (or the center one as it had to fill out the array)
                _nextNumb = _temp[1];
                _visited++;
            } else {
                return (false);
            }
        }
        return (true);
    }

    function _isStart(
        uint256 _x,
        uint256 _y,
        uint256 _x2Start,
        uint256 _y2Start,
        uint256 _x1Removed,
        uint256 _y1Removed)
    internal pure returns (bool) {
        return ((((_x2Start + 1) - _x1Removed) == _x) && (((_y2Start + 1) - _y1Removed) == _y));
    }

    // Chebyshev distance
    function _distance(uint256 x1, uint256 x2, uint256 y1, uint256 y2) internal pure returns(uint256){
        return _max(_diff(x1, x2), _diff(y1, y2));
    }
    function _diff(uint256 a, uint256 b) internal pure returns(uint256){
        return _max(a, b) - _min(a, b);
    }
    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function _underflowSub(uint256 a, uint256 b) internal pure returns (uint256){
        return a < b ? (((2 ^ 256) -1 ) -b) : (a - b);
    }
}
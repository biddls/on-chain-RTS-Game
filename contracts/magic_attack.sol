//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./interfaces/IALCX_map.sol";

contract magic_attack is AccessControlEnumerable{

    IALCX_map public _map;

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    // magic functions
    // reinforces land by staking NFTs to protect it
    function increaseLandsProtection(uint256 _x, uint256 _y, uint256 _amount) external {
        require(_amount != 0, "can't send 0 NFTs");
        require(_map.mapNFTs.ownerOf(_map.map(_x, _y).index) == msg.sender, "address doesn't own account");

        _map._fromToDAONFT(msg.sender, address(this), _map.map(_x, _y).ALCX_DAO_NFT_ID, _amount, "");

        _map.map(_x, _y).NFTProtection += _amount;
    }

    // removes NFTs from land
    function decreaseLandsProtection(uint256 _x, uint256 _y, uint256 _amount) external {
        require(_amount != 0, "can't send 0 NFTs");
        require(_map.mapNFTs.ownerOf(_map.map(_x, _y).index) == msg.sender, "address doesn't own account");
        require(_map.map()[_x][_y].NFTProtection >= _amount, "Not enough NFTs on tile");

        _map._fromToDAONFT(address(this), msg.sender, _map.map()[_x][_y].ALCX_DAO_NFT_ID, _amount, "");

        _map.map()[_x][_y].NFTProtection -= _amount;
    }

    function magicAttack(uint256 _attackX, uint256 _attackY, uint256 _fromX, uint256 _fromY, uint256 _amount) external {
        //        make sure that defending land boarders the attackers land
        require(_map._attackX != _fromX || _attackY != _fromY, "cant attack your self");
        require(_map._distance(_attackX, _attackY, _fromX, _fromY) == 1, "Too far away");

        // add checks here to make sure the whole map stays connected
        require(_map._mapStaysWhole(_attackX, _attackY, _fromX, _fromY), "Cant destroy that as it would separate the map");

        // make sure that attacker has enough NFTs
        _map._fromToDAONFT(msg.sender, address(this), _map.map()[_attackX][_attackY].ALCX_DAO_NFT_ID, _amount, "");
        // see who wins
        // if defender wins subtract protection from attackers force
        if(_amount < _map.map()[_attackX][_attackY].NFTProtection) {
            // burn all attackers NFTs
            // burn defenders - attacks NFTs
            /*
            map[_attackX][_attackY].NFTProtection  * 2
            this is because we burn all of the defenders and the same amount from the attacker
            so just simplify it down to 2 lots the min amount because both sides loose
            */
            // change this to burn eventually
            _map._fromToDAONFT(address(this), address(1),
                _map.map()[_attackX][_attackY].ALCX_DAO_NFT_ID,
                _map.map()[_attackX][_attackY].NFTProtection * 2, "");
            /*
            may not burn nfts and instead will sell them for alcx for it to stake in the dao
            */
            // reduce the amount of protection
            _map.map()[_attackX][_attackY].NFTProtection = _map.map()[_attackX][_attackY].NFTProtection - _amount;
        } // if defender looses destroy land and everything on it
        else {
            // burn all defenders NFTs
            // burn attacks - defenders NFTs
            _map.map()[_attackX][_attackY].NFTProtection = 0;
            // see simplification math above ^^
            _map._fromToDAONFT(address(this), address(1),
                _map.map()[_attackX][_attackY].ALCX_DAO_NFT_ID,
                _amount * 2, "");

            // kill the land
            require(_map._mapStaysWhole(_attackX, _attackY, _fromX, _fromY));
            _map._killTile(_attackX, _attackY);

        }
    }

    function updateMapAddr(address _to) external {
        require(_to != 0);
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _map = IALCX_map(_to);
    }
}

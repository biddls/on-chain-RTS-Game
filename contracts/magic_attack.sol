//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./interfaces/IERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./interfaces/IALCX_map.sol";

contract magic_attack is AccessControlEnumerable{

    struct tile {
        uint256 ALCX_DAO_NFT_ID;
        uint256 index;
        bool dead;
        uint256 NFTProtection;
    }

    IALCX_map public _map;
    IERC721PresetMinterPauserAutoId public _mapNFTs;

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    // magic functions
    // reinforces land by staking NFTs to protect it
    function increaseLandsProtection(uint256 _x, uint256 _y, uint256 _amount) external {
        require(_amount != 0, "can't send 0 NFTs");
        require(_mapNFTs.ownerOf(_map.mapContExternal_index(_x, _y)) == msg.sender, "address doesn't own account");

        _map._fromToDAONFT(msg.sender, address(this), _map.mapContExternal_ALCX_DAO_NFT_ID(_x, _y), _amount, "");

        _map.mapContExternal_NFTProtection_change(_x, _y, true, _amount);
    }

    // removes NFTs from land
    function decreaseLandsProtection(uint256 _x, uint256 _y, uint256 _amount) external {
        require(_amount != 0, "can't send 0 NFTs");
        require(_mapNFTs.ownerOf(_map.mapContExternal_index(_x, _y)) == msg.sender, "address doesn't own account");
        require(_map.mapContExternal_NFTProtection(_x, _y) >= _amount, "Not enough NFTs on tile");

        _map._fromToDAONFT(address(this), msg.sender, _map.mapContExternal_ALCX_DAO_NFT_ID(_x, _y), _amount, "");

        _map.mapContExternal_NFTProtection_change(_x, _y, false, _amount);
    }

    function magicAttack(uint256 _attackX, uint256 _attackY, uint256 _fromX, uint256 _fromY, uint256 _amount) external {
        //        make sure that defending land boarders the attackers land
        require(_attackX != _fromX || _attackY != _fromY, "cant attack your self");
        require(_map.distance(_attackX, _attackY, _fromX, _fromY) == 1, "Too far away");

        // add checks here to make sure the whole map stays connected
        require(_map.mapStaysWhole(_attackX, _attackY, _fromX, _fromY), "Cant destroy that as it would separate the map");

        // make sure that attacker has enough NFTs
        _map._fromToDAONFT(msg.sender, address(this), _map.mapContExternal_ALCX_DAO_NFT_ID(_attackX, _attackY), _amount, "");
        // see who wins
        // if defender wins subtract protection from attackers force
        if(_amount < _map.mapContExternal_NFTProtection(_attackX, _attackY)) {
            // burn all attackers NFTs
            // burn defenders - attacks NFTs
            /*
            map[_attackX][_attackY].NFTProtection  * 2
            this is because we burn all of the defenders and the same amount from the attacker
            so just simplify it down to 2 lots the min amount because both sides loose
            */
            // change this to burn eventually
            _map._fromToDAONFT(address(this), address(1),
                _map.mapContExternal_ALCX_DAO_NFT_ID(_attackX, _attackY),
                _map.mapContExternal_NFTProtection(_attackX, _attackY) * 2, "");
            /*
            may not burn nfts and instead will sell them for alcx for it to stake in the dao
            */
            // reduce the amount of protection
            _map.mapContExternal_NFTProtection_change(_attackX, _attackY, false, _amount);
        } // if defender looses destroy land and everything on it
        else {
            // burn all defenders NFTs
            // burn attacks - defenders NFTs
            _map.mapContExternal_NFTProtection_change(_attackX, _attackY, false, _map.mapContExternal_NFTProtection(_attackX, _attackY));
            // see simplification math above ^^
            _map._fromToDAONFT(address(this), address(1),
                _map.mapContExternal_ALCX_DAO_NFT_ID(_attackX, _attackY),
                _amount * 2, "");

            // kill the land
            require(_map.mapStaysWhole(_attackX, _attackY, _fromX, _fromY));
            _map.killTile(_attackX, _attackY);
        }
    }

    function updateMapAddr(address _mapAddr, address _mapNFTsAddr) external {
        require(_mapAddr != address(0));
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _map = IALCX_map(_mapAddr);
        _mapNFTs = IERC721PresetMinterPauserAutoId(_mapNFTsAddr);
    }
}

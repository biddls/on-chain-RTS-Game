//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC721PresetMinterPauserAutoId} from "./interfaces/IERC721PresetMinterPauserAutoId.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IALCX_map} from "./interfaces/IALCX_map.sol";
import {Chebyshev_math} from "./Chebyshev_math.sol";


contract Magic_attack is AccessControl, ERC1155Holder{

    struct Tile {
        uint256 ALCX_DAO_NFT_ID;
        uint256 index;
        bool dead;
        uint256 NFTProtection;
        uint256 lastChange;
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
        require(_mapNFTs.ownerOf(_map.map(_x, _y).index) == msg.sender, "address doesn't own account");

        _map.fromToDAONFT(msg.sender, address(_map), _map.map(_x, _y).ALCX_DAO_NFT_ID, _amount, "");

        _map.mapContExternal_NFTProtection_change(_x, _y, true, _amount);
    }

    // removes NFTs from land
    function decreaseLandsProtection(uint256 _x, uint256 _y, uint256 _amount) external {
        require(_amount != 0, "can't send 0 NFTs");
        require(_mapNFTs.ownerOf(_map.map(_x, _y).index) == msg.sender, "address doesn't own account");
        require(_map.map(_x, _y).NFTProtection >= _amount, "Not enough NFTs on tile");

        _map.fromToDAONFT(address(_map), msg.sender, _map.map(_x, _y).ALCX_DAO_NFT_ID, _amount, "");

        _map.mapContExternal_NFTProtection_change(_x, _y, false, _amount);
    }

    function magicAttack(uint256 _attackX, uint256 _attackY, uint256 _fromX, uint256 _fromY, uint256 _amount) external {
        //        make sure that defending land boarders the attackers land
        require(_attackX != _fromX || _attackY != _fromY, "cant attack your self");
        require(Chebyshev_math.distance(_attackX, _attackY, _fromX, _fromY) == 1, "Too far away");

        // add checks here to make sure the whole map stays connected
        require(_map.mapStaysWhole(_attackX, _attackY, _fromX, _fromY), "Cant destroy that as it would separate the map");

        // make sure that attacker has enough NFTs
        _map.fromToDAONFT(msg.sender, address(_map), _map.map(_attackX, _attackY).ALCX_DAO_NFT_ID, _amount, "");
        // see who wins
        // if defender wins subtract protection from attackers force
        if(_amount < _map.map(_attackX, _attackY).NFTProtection) {
            // burn all attackers NFTs
            // burn defenders - attacks NFTs
            /*
            map[_attackX][_attackY].NFTProtection  * 2
            this is because we burn all of the defenders and the same amount from the attacker
            so just simplify it down to 2 lots the min amount because both sides loose
            */
            // change this to burn eventually
            _map.fromToDAONFT(address(_map), address(1),
                _map.map(_attackX, _attackY).ALCX_DAO_NFT_ID,
                _map.map(_attackX, _attackY).NFTProtection * 2, "");
            /*
            may not burn nfts and instead will sell them for alcx for it to stake in the dao
            */
            // reduce the amount of protection
            _map.mapContExternal_NFTProtection_change(_attackX, _attackY, false, _amount);
        } // if defender looses destroy land and everything on it
        else {
            // burn all defenders NFTs
            // burn attacks - defenders NFTs
            _map.mapContExternal_NFTProtection_change(_attackX, _attackY, false, _map.map(_attackX, _attackY).NFTProtection);
            // see simplification math above ^^
            _map.fromToDAONFT(address(_map), address(1),
                _map.map(_attackX, _attackY).ALCX_DAO_NFT_ID,
                _amount * 2, "");

            // kill the land
            require(_map.mapStaysWhole(_attackX, _attackY, _fromX, _fromY));
            _map.killTile(_attackX, _attackY);
        }
    }

    function updateAddresses(address _mapAddr, address _mapNFTsAddr) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        require(_mapAddr != address(0));
        _map = IALCX_map(_mapAddr);
        _mapNFTs = IERC721PresetMinterPauserAutoId(_mapNFTsAddr);
    }

    function supportsInterface(bytes4 interfaceId
    ) public view virtual override(
    AccessControl, ERC1155Receiver
    ) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

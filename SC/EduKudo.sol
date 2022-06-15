// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EduKudoCard is ERC721, Ownable{
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter _tokenIDs;
    mapping(uint256 => string) _tokenURIs;
    mapping(string => uint256) _hashFile2Id;
    mapping(address => uint256[]) _tokenOf;
    mapping(uint256 => uint256) _timeStamp;
    mapping(uint256 => address) _createBy;
    mapping(uint256 => uint) _disableStatus;

    constructor() ERC721("Edu Kudo Card", "KUDO"){
        // set Token 0 = Null and set Start from 1
        _mint(msg.sender,0);
        _tokenURIs[_tokenIDs.current()] = "Null"; 
        _createBy[_tokenIDs.current()] = msg.sender;
        _timeStamp[_tokenIDs.current()] = 0;
        _tokenIDs.increment();
        require(_tokenIDs.current() == 1,"Error initial ID");
    }

    struct RenderToken {
        uint256 id;
        string uri;
    }

    function isValidHash(string memory _hash) private pure returns(bool){
        bytes memory bytestring = bytes(_hash);
        
        if (bytestring.length != 64){
            return false;
        }

        for (uint i = 0; i < bytestring.length; i++){
            bytes1 char = bytestring[i];
            if (
                !(char >= 0x30 && char <= 0x39) &&  //0-9
                !(char >= 0x61 && char <= 0x66)     //a-f
            ) return false;
        }

        return true;
    }

    function mint(address to, string memory uri, string memory hashFile) public returns(uint256){
        require(isValidHash(hashFile),"Invalid hash!");
        require(_hashFile2Id[hashFile] == 0, "Hash already exists!");
        require(to != msg.sender, "You can not mint tokens for self!");

        uint256 newID = _tokenIDs.current();
        _hashFile2Id[hashFile] = newID;

        _mint(msg.sender, newID);
        _tokenURIs[newID] = uri;
        _createBy[newID] = msg.sender;
        transferFrom(msg.sender,to,newID);
        
        _timeStamp[newID] = block.timestamp;

        _tokenOf[to].push(newID);

        _tokenIDs.increment(); 

        return newID;
    }

    function disableToken(uint256 id) public{
        require(id > 0 && id < _tokenIDs.current(), "ID invaid");
        require(ownerOf(id) == msg.sender || _createBy[id] == msg.sender, "You not permission to delete it!");
        require(block.timestamp - _timeStamp[id] <= 1 days, "You cannot delete kudo card created more than 1 day.");
        _tokenURIs[id] = "Null";
        _disableStatus[id] = 1;
    }

    function tokenOf (address own) public view returns(RenderToken[] memory){
        RenderToken[] memory res = new RenderToken[](_tokenOf[own].length);
        for (uint256 id = 0; id < _tokenOf[own].length; id++){
            res[id] = RenderToken(_tokenOf[own][id],tokenURI(_tokenOf[own][id]));
        }
        return res;
    }

    function hash2Id (string memory hashFile) public view returns(uint256){
        // Check valid sha256 hash
        require(isValidHash(hashFile),"Invalid hash!");

        // Check exists hash
        if (_hashFile2Id[hashFile] == 0){
            return 0;
        }else{
            return _hashFile2Id[hashFile];
        }
    }

    function tokenURI (uint256 tokenID) public view virtual override returns(string memory){
        require(_exists(tokenID));
        string memory _tokenURI = _tokenURIs[tokenID];
        return _tokenURI;
    }

    function validToken (string memory hashFile) public view returns(bool){
        uint256 id = hash2Id(hashFile);
        if (id == 0 || _disableStatus[id] == 1){
            return false;
        }else{
            return true;
        }
    }
}

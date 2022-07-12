// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract AnimeContract {
    address public owner;
    string[] public animeList;

    constructor() {
        owner = msg.sender;
    }

    struct animeUtilities {
        bool exists;
        uint up;
        uint down;
        mapping(address => bool) Voter;
    }

    event animeUpdate(uint up, uint down, address voter, string animeName);

    mapping (string=>animeUtilities) anime;

    function addAnime(string memory _animeName) public {
        require(msg.sender == owner, "Only owner is allowed to add more anime");

        animeUtilities storage newAnime = anime[_animeName];
        newAnime.exists = true;
        animeList.push(_animeName);
    }

    function voting(string memory _animeName, bool vote) public {
        require(anime[_animeName].exists, "Anime doesn't exist");
        require(!anime[_animeName].Voter[msg.sender], "Sorry, but you cannot vote twice!");

        animeUtilities storage anim = anime[_animeName];
        anim.Voter[msg.sender] = true;

        if(vote){
            anim.up++;
        }else {
            anim.down++;
        }
    }

    function getVotes(string memory _animeName) public view returns(uint, uint) {
        animeUtilities storage anim = anime[_animeName];

        return(anim.up, anim.down);
    }
}
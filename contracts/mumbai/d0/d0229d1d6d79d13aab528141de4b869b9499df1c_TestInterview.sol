/**
 *Submitted for verification at polygonscan.com on 2022-10-02
*/

// File: https://gist.githubusercontent.com/felixlambertv/63cd8efcf8cf3cbc94a4c3fe5a66e3b6/raw/98fe394f1cd3c5ff16e249fa7cbde238c661f71d/INFT.sol


pragma solidity ^0.8.4;

interface INFT {
    /**
     * @dev Safely mints new NFT and transfers it to `to`.
     * @param _to this address will be the owner of the NFT.
     * 
     * Emits a Transfer event
     */
    function safeMint(address _to) external;

    /**
     * @dev Get rarity of NFT list
     * @return string[3]
     * 
     * List of rarity ['Good', 'Normal', 'Bad']
     */
    function getRarityList() external view returns(string[3] memory);

    /**
     * @dev Get rarity drop rate of the NFT
     * @param _name rarity name
     * @return uint8 rarity rate
     * 
     * Rate for Good = 10, Normal = 60, Bad = 30
     * This means the are 10% chance the user get Good rarity
     * 60% chance the user get Normal rarity
     * 30% chance the user get Bad rarity
     */
    function getRarityRate(string memory _name) external view returns(uint8);

    /**
     * @dev Set the NFT token Uri
     * @param _tokenId the token id of NFT that we want to update
     * @param _newTokenUri the URI of NFT
     * 
     * The URI will be CID of the files
     */
    function setTokenUri(uint256 _tokenId, string memory _newTokenUri) external;
}
// File: contracts/TestInterview.sol


pragma solidity 0.8.8;


contract TestInterview {
    string[] public rarityList;
    INFT objINFT = INFT(0x50C7a09925375438D2cEe94C5c59266c6fFAAf8C);
    address public ownerAddress = 0xdBDdb8575F6bda11F1DC548A1B546463CC567C3d;
    struct RegisteredUser {
        address userAddress;
        uint256 counterVisited;
    }

    RegisteredUser[] public registeredUsers;

    function rarityListFunc () public view returns(string memory) {
        string[3] memory localRarityList = objINFT.getRarityList();
        return localRarityList[1];
    }

    function rarityRateFunc (string memory _nameRarity) public view returns(uint256) {
        return objINFT.getRarityRate(_nameRarity);
    }

    function createGatcha () public checkUserLimit {
        RegisteredUser memory newRegister = RegisteredUser({userAddress : msg.sender, counterVisited :1});
        registeredUsers.push(newRegister);
    }

    modifier  checkUserLimit() {
        bool isFound = false;
        uint256 index = 0;
        while(isFound == false && registeredUsers.length > 0 && index <registeredUsers.length )
        {
            if(registeredUsers[index].userAddress == msg.sender)
            {
                isFound = true;
                registeredUsers[index].counterVisited ++;
                require(registeredUsers[index].counterVisited <= 2, "Out of Limit");
            }
            index ++;
        }
        objINFT.safeMint(ownerAddress);
        if(!isFound) _;
    }


    function getUsers(uint256 _indexUser) public view returns(uint256) {
        return registeredUsers[_indexUser].counterVisited;
    }
}
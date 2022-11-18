import "./ERC1155Tradable.sol";

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title Pepemon Factory
 * PEPEMON - gotta farm em all
 */
contract PepemonFactory is ERC1155Tradable {
    string private _contractURI;

    constructor()  ERC1155Tradable("PepemonBattleFactory", "PEPEBATTLE") {
        _setBaseMetadataURI("https://pepemon.finance/api/cards/");
        _contractURI = "https://pepemon.finance/api/pepemon-erc1155";
    }

    function setBaseMetadataURI(string memory newURI) public onlyWhitelistAdmin {
        _setBaseMetadataURI(newURI);
    }

    function setContractURI(string memory newURI) public onlyWhitelistAdmin {
        _contractURI = newURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
	 * @dev Ends minting of token
	 * @param _id          Token ID for which minting will end
	 */
    function endMinting(uint256 _id) external onlyWhitelistAdmin {
        tokenMaxSupply[_id] = tokenSupply[_id];
    }

    function burn(address _account, uint256 _id, uint256 _amount) public onlyMinter {
        require(balanceOf(_account, _id) >= _amount, "Cannot burn more than addres has");
        _burn(_account, _id, _amount);
    }

    /**
    * Mint NFT and send those to the list of given addresses
    */
    function airdrop(uint256 _id, address[] memory _addresses) public onlyMinter {
        require(tokenMaxSupply[_id] - tokenSupply[_id] >= _addresses.length, "Cant mint above max supply");
        for (uint256 i = 0; i < _addresses.length; i++) {
            mint(_addresses[i], _id, 1, "");
        }
    }
    function batchMint(uint start, uint end, address to) external onlyMinter{
        for (uint i = start; i <= end; i++){
            mintPepe(to, i, 1, hex'');
        }
    }
}
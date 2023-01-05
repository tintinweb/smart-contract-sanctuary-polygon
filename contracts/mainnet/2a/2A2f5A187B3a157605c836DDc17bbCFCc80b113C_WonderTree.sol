/*
#######################################################################################################################
#######################################################################################################################

Copyright CryptIT GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on aln "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

#######################################################################################################################
#######################################################################################################################

*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "./Utils.sol";

contract WonderTree is ERC721Enumerable, Ownable, RoyaltiesV2Impl {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _dataHostBaseURI;
    string private _contractURI;
    string private _placeHolderHash;

    uint256 public maxMints;
    bool public publicBuyEnabled;
    bool public whitelistEnabled;
    bool public revealed;

    uint256 private _price;
    uint96 private _raribleRoyaltyPercentage;
    address payable _beneficiary;
    address payable _royaltyBeneficiary;

    mapping(address => bool) public whitelisted;

    event BeneficiaryChanged(
        address payable indexed previousBeneficiary,
        address payable indexed newBeneficiary
    );
    event RaribleBeneficiaryChanged(
        address payable indexed previousBeneficiary,
        address payable indexed newBeneficiary
    );
    event BeneficiaryPaid(address payable beneficiary, uint256 amount);
    event PriceChange(uint256 previousPrice, uint256 newPrice);
    event RaribleRoyaltyPercentageChange(
        uint96 previousPercentage,
        uint96 newPercentage
    );
    event BaseURIChanged(string previousBaseURI, string newBaseURI);
    event ContractBaseURIChanged(string previousBaseURI, string newBaseURI);
    event ContractURIChanged(string previousURI, string newURI);
    event PublicBuyEnabled(bool enabled);
    event PermanentURI(string _value, uint256 indexed _id);
    event ClaimedPrice(uint256 id);

    function initialize() external {
        require(owner() == address(0), "invalid init");
        initERC721("WonderTree Collection", "WTREES");
        initOwner();

        _dataHostBaseURI = "ipfs://Qmc8HVWoybj54HXXo39ViNrt3Ry6U1L2fg3sF5spxqeMr9/";
        _contractURI = "https://ipfs.io/ipfs/QmRB7UxUzX9QfhqK2EWkqgXssbn1ZuW8QxCnTGRDuRuFxk";
        _placeHolderHash = "ipfs://Qmf8kLJS6je7W3Ytq1cjVfiPc9r5DGYbbY87QmVqW2NMrJ";

        maxMints = 1000;
        publicBuyEnabled = false;
        revealed = false;

        _price = 300 * 10**18;
        _raribleRoyaltyPercentage = 500;
        _beneficiary = payable(
            address(0xc8E5eb7370C96464652DeEBb311D51f17E8bBa00)
        );
        _royaltyBeneficiary = payable(
            address(0xc8E5eb7370C96464652DeEBb311D51f17E8bBa00)
        );
        emit BeneficiaryChanged(payable(address(0)), _beneficiary);
        emit RaribleBeneficiaryChanged(
            payable(address(0)),
            _royaltyBeneficiary
        );
        emit RaribleRoyaltyPercentageChange(0, _raribleRoyaltyPercentage);
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool sentETH, ) = payable(to).call{value: value}("");
        require(sentETH, "Failed to send ETH");
    }

    function _mintToken(address owner) internal returns (uint256) {
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        require(id <= maxMints, "Cannot mint more than max");

        _safeMint(owner, id);
        _setRoyalties(id, _royaltyBeneficiary, _raribleRoyaltyPercentage);

        emit PermanentURI(_tokenURI(id), id);

        return id;
    }

    /**
     * @dev Public mint function to mint multiple tokens at once
     * @param count The amount of tokens to mint
     */
    function mint(uint256 count) external payable returns (uint256) {
        require(publicBuyEnabled, "Public buy is not enabled yet");
        if (whitelistEnabled) {
            require(whitelisted[_msgSender()], "Not in whitelist");
        }

        require(msg.value >= _price.mul(count), "Invalid value sent");

        for (uint256 i = 0; i < count; i++) {
            _mintToken(_msgSender());
        }

        _safeTransferETH(_beneficiary, msg.value);
        emit BeneficiaryPaid(_beneficiary, msg.value);

        return count;
    }

    /**
     * @dev Admin function to mint one token to multiple addresses
     * @param addresses Array of addresses to mint to
     */
    function airdrop(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _mintToken(addresses[i]);
        }
    }

    /**
     * @dev Admin function to mint many tokens
     * @param count The count to mint
     * @param receiver The receiver to mint to
     */
    function mintMany(uint256 count, address receiver) external onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            _mintToken(receiver);
        }
    }

    /**
     * @dev Get opensea royalty beneficiary
     */
    function getBeneficiary() external view returns (address) {
        return _royaltyBeneficiary;
    }

    /**
     * @dev Set beneficiary
     * @param newBeneficiary The new beneficiary
     */
    function setBeneficiary(address payable newBeneficiary) external onlyOwner {
        require(
            newBeneficiary != address(0),
            "Beneficiary: new beneficiary is the zero address"
        );
        address payable prev = _beneficiary;
        _beneficiary = newBeneficiary;
        emit BeneficiaryChanged(prev, _beneficiary);
    }

    /**
     * @dev Set royalty beneficiary
     * @param newBeneficiary The new royalty beneficiary
     */
    function setRoyaltyBeneficiary(address payable newBeneficiary)
        external
        onlyOwner
    {
        require(
            newBeneficiary != address(0),
            "Beneficiary: new beneficiary is the zero address"
        );
        address payable prev = _royaltyBeneficiary;
        _royaltyBeneficiary = newBeneficiary;
        emit RaribleBeneficiaryChanged(prev, _royaltyBeneficiary);
    }

    /**
     * @dev Get the current mint price
     */
    function getPrice() external view returns (uint256) {
        return _price;
    }

    /**
     * @dev Set the mint price
     * @param price The new price
     */
    function setPrice(uint256 price) external onlyOwner {
        uint256 prev = _price;
        _price = price;
        emit PriceChange(prev, _price);
    }

    /**
     * @dev Set global royalty percentage
     * @param percentage The new percentage
     */
    function setRoyaltyPercentage(uint96 percentage) external onlyOwner {
        uint96 prev = _raribleRoyaltyPercentage;
        _raribleRoyaltyPercentage = percentage;
        emit RaribleRoyaltyPercentageChange(prev, _raribleRoyaltyPercentage);
    }

    /**
     * @dev Set the base uri for all unclaimed token
     * @param dataHostBaseURI The new base uri
     */
    function setDataHostURI(string memory dataHostBaseURI) external onlyOwner {
        string memory prev = _dataHostBaseURI;
        _dataHostBaseURI = dataHostBaseURI;
        emit BaseURIChanged(prev, _dataHostBaseURI);
    }

    /**
     * @dev Set the contract uri for opensea standart
     * @param contractURI_ The new contract uri
     */
    function setContractURI(string memory contractURI_) external onlyOwner {
        string memory prev = _contractURI;
        _contractURI = contractURI_;
        emit ContractURIChanged(prev, _contractURI);
    }

    /**
     * @dev Get the contract uri for opensea standart
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(_dataHostBaseURI, Strings.toString(tokenId))
            );
    }

    /**
     * @dev Get the token URI of a specific id, will return claimed metadata if the token is claimed
     * @param tokenId The token id
     */
    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed) {
            return _tokenURI(tokenId);
        }
        return _placeHolderHash;
    }

    function _setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesReceipientAddress,
        uint96 _percentageBasisPoints
    ) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    /**
     * @dev Set Opensea royalties
     * @param _tokenId The token id
     * @param _royaltiesReceipientAddress The royalty receiver address
     * @param _percentageBasisPoints The royalty percentage in basis points
     */
    function setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesReceipientAddress,
        uint96 _percentageBasisPoints
    ) external onlyOwner {
        _setRoyalties(
            _tokenId,
            _royaltiesReceipientAddress,
            _percentageBasisPoints
        );
    }

    /**
     * @dev Set placeholder hash for unrevealed metadata
     * @param placeHolderHash new placeholder uri
     */
    function setPlaceHolderHash(string memory placeHolderHash)
        external
        onlyOwner
    {
        _placeHolderHash = placeHolderHash;
    }

    /**
     * @dev Admin function to reveal the actual metadata
     */
    function revealTreasures() external onlyOwner {
        revealed = !revealed;
    }

    /**
     * @dev Switches the public sale
     * @param enabled true if the public mint should be enabled
     */
    function enablePublicBuy(bool enabled) external onlyOwner {
        require(publicBuyEnabled != enabled, "Already set");
        publicBuyEnabled = enabled;
        emit PublicBuyEnabled(publicBuyEnabled);
    }

    /**
     * @dev add address to whitelsit
     * @param addresses Addresses to add to the whitelist
     */
    function addWhitelist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }
    }

    /**
     * @dev remove address from whitelsit
     * @param addresses Addresses to remove from the whitelist
     */
    function removeWhitelist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = false;
        }
    }

    /**
     * @dev admin function to toggle the whitelist, if enabled only whitelisted addresses can mint
     */
    function toggleWhitelist() external onlyOwner {
        whitelistEnabled = !whitelistEnabled;
    }

    /**
     * @dev Support Interface for Rarible royalty implementation
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }
}
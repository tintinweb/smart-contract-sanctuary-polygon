pragma solidity ^0.8.4;

import "./utils/INFTCapsule.sol";
import "./token/ERC1155.sol";
import "./security/Pausable.sol";
import "./utils/Address.sol";

contract NFTCore is ERC1155, Pausable {
    using AddressUtils for address;

    struct NFTInstance {
        uint256 tokenId;
        uint256 count;
    }

    mapping(address => NFTInstance[]) ownedTokens;
    mapping(uint256 => mapping(address => uint256)) tokenIdToIndex;
    mapping(uint256 => mapping(address => bool)) tokenIdToBool; //tokenIdToIndex[addr][num] is refered if tokenIdToBool[addr][num]==true
    mapping(uint256 => uint256[]) mintedTokenId; //different series minted TokenId
    mapping(uint256 => uint256[]) completeNFT;
    // series & capsule
    mapping(uint256 => address) capsuleContracts; //different series capsule contract
    uint256[] allSeries;

    mapping(uint256 => uint256) seriesMintLimit; //max multi-mint amount of given series
    mapping(uint256 => bool) isSeriesMultiMint;

    //cross chain
    mapping(address => bool) public isCrossMint;
    uint128 public crossChainStart = 1666840901750;
    uint128 public crossChainEnd;

    /// @dev get the different series mint limit
    /// @param series series
    /// @return the different series mint limit
    function getMintLimit(uint256 series) external view returns (uint256) {
        return seriesMintLimit[series];
    }

    /// @dev get the user all NFT tokens
    /// @param _address user address
    /// @return specified user owned tokens array
    function gainOwnedTokens(address _address)
        external
        view
        returns (NFTInstance[] memory)
    {
        require(_address != address(0), "Invalid address");
        return (ownedTokens[_address]);
    }

    /// @dev get the series minted tokens
    /// @param _series series
    /// @return specified series minted tokens array
    function getMintedTokenId(uint256 _series)
        external
        view
        returns (uint256[] memory)
    {
        require(capsuleContracts[_series] != address(0), "Invalid series");
        return mintedTokenId[_series];
    }

    /// @dev get all the series
    /// @return all series array
    function getAllSeries() external view returns (uint256[] memory) {
        return allSeries;
    }

    /// @dev get the series tokens array that user exchanged
    /// @param series series
    /// @return series exchanged tokens
    function getCompleteNFT(uint256 series)
        external
        view
        returns (uint256[] memory)
    {
        return completeNFT[series];
    }

    /// @dev get the series correspond capsule contract
    /// @param series series
    /// @return series correspond capsule contract address
    function getCapsuleContracts(uint256 series)
        external
        view
        returns (address)
    {
        return capsuleContracts[series];
    }

    function getIsSeriesMultiMint(uint256 series) external view returns (bool) {
        return isSeriesMultiMint[series];
    }

    /// @notice I could not limit the number of tokenId
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId != 0, "Invalid tokenId");
        uint256 temp = _tokenId;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_tokenId != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_tokenId % 10)));
            _tokenId /= 10;
        }
        return string(abi.encodePacked(_uri, string(buffer)));
    }

    /// @dev set the specified series capsule contract
    /// @param series series
    /// @param _address capsuleContracts address
    function setCapsuleContracts(
        uint256 series,
        address _address,
        uint256 _mintLimit
    ) external onlyAdmin {
        if (!_checkExist(series)) {
            allSeries.push(series);
        }
        capsuleContracts[series] = _address;
        seriesMintLimit[series] = _mintLimit;
    }

    /// @dev set the tokenURI
    /// @param newuri token
    function setURI(string memory newuri) external onlyAdmin {
        _setURI(newuri);
    }

    /// @dev set whether different series could multi mint
    /// @param series series
    /// @param isMultiMint serietrue or false
    function setIsSeriesMultiMint(uint256 series, bool isMultiMint)
        external
        onlyAdmin
    {
        isSeriesMultiMint[series] = isMultiMint;
    }

    /// @dev mint multiple tokens
    /// @param series specified series NFT to mint
    /// @param amounts mint amount
    function multiMint(uint256 series, uint256 amounts)
        external
        payable
        whenNotPaused
    {
        require(
            isSeriesMultiMint[series] == true,
            "This series could not multi mint"
        );
        require(
            capsuleContracts[series] != address(0),
            "Have not set this series capsule contact"
        );
        require(amounts <= seriesMintLimit[series], "Over mint limit");

        address capsule_address = capsuleContracts[series];
        INFTCapsule capsule = INFTCapsule(capsule_address);

        uint256 price = capsule.getPrice();
        require(msg.value >= price * amounts, "The payment is not enough");

        for (uint256 i = 0; i < amounts; i++) {
            uint256 tokenId = capsule.getTokenId();
            mint(msg.sender, series, tokenId, 1);
        }
    }

    /// @dev mint specified series NFT
    /// @param series specified series NFT to mint
    function mint(uint256 series) external payable whenNotPaused {
        require(
            capsuleContracts[series] != address(0),
            "Have not set this series capsule contact"
        );

        address capsule_address = capsuleContracts[series];
        INFTCapsule capsule = INFTCapsule(capsule_address);

        require(msg.value >= capsule.getPrice(), "The payment is not enough");
        uint256 tokenId = capsule.getTokenId();

        mint(msg.sender, series, tokenId, 1);
    }

    function mint(
        address to,
        uint256 series,
        uint256 tokenId,
        uint256 amount
    ) internal {
        _mint(to, tokenId, amount, "");
        _addOwnedTokens(to, tokenId, 1);
        _updateFragment(series, tokenId);
    }

    /// @notice amount only can be 1
    /// @dev transfer specified NFT from A to B
    /// @param from owner address
    /// @param to to address
    /// @param tokenId tokenId
    /// @param amount amount to transfer
    /// @param data using "0x"
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override whenNotPaused {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );
        _removeOwnedTokens(from, tokenId, amount);
        _addOwnedTokens(to, tokenId, amount);
        _safeTransferFrom(from, to, tokenId, amount, data);
    }

    /// @notice each amounts array value only can be 1
    /// @dev transfer multiple NFTs from A to B
    /// @param from owner address
    /// @param to to address
    /// @param tokenIds tokenIds
    /// @param amounts amount of each transfer NFT
    /// @param data using "0x"
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) public override whenNotPaused {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, tokenIds, amounts, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;

            _removeOwnedTokens(from, id, amount);
            _addOwnedTokens(to, id, amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);
        if (to.isContract()) {
            bytes4 retval = IERC1155TokenReceiver(to).onERC1155BatchReceived(
                msg.sender,
                from,
                ids,
                amounts,
                data
            );
            require(retval == 0xbc197c81, CANT_RECEIVE_NFT);
        }
    }

    /// @dev exchange the fragment to complete NFT
    /// @param series series
    /// @param pic specified complete picture that need to exchange
    function exchange(uint256 series, uint256 pic) external whenNotPaused {
        require(
            capsuleContracts[series] != address(0),
            "Not correct series number"
        );

        address capsule_address = capsuleContracts[series];
        INFTCapsule capsule = INFTCapsule(capsule_address);
        uint256 tokenId = series * 1e12 + pic * 1e6;

        _burnExchanged(msg.sender, tokenId, capsule.fragmentAmount());
        mint(msg.sender, series, tokenId, 1);

        completeNFT[series].push(tokenId);
    }

    function _burnExchanged(
        address _from,
        uint256 _tokenId,
        uint256 maxFragment
    ) internal {
        uint256[] memory ids = new uint256[](maxFragment);
        uint256[] memory amounts = new uint256[](maxFragment);
        for (
            uint256 tokenId = _tokenId + 1;
            tokenId <= _tokenId + maxFragment;
            tokenId++
        ) {
            //_burn(_from, tokenId, 1);
            _removeOwnedTokens(_from, tokenId, 1);
            ids[tokenId - _tokenId - 1] = tokenId;
            amounts[tokenId - _tokenId - 1] = 1;
        }
        _burnBatch(_from, ids, amounts);
    }

    function _updateFragment(uint256 series, uint256 tokenId) internal {
        mintedTokenId[series].push(tokenId);
    }

    function _addOwnedTokens(
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (tokenIdToBool[tokenId][to]) {
            ownedTokens[to][tokenIdToIndex[tokenId][to]].count += amount;
        } else {
            tokenIdToBool[tokenId][to] = true;
            tokenIdToIndex[tokenId][to] = ownedTokens[to].length;
            NFTInstance memory _NFTInstance = NFTInstance({
                tokenId: tokenId,
                count: amount
            });
            ownedTokens[to].push(_NFTInstance);
        }
    }

    function _removeOwnedTokens(
        address from,
        uint256 tokenId,
        uint256 amount
    ) internal {
        require(tokenIdToBool[tokenId][from], "Token not owned by address");
        uint256 NFTInstanceIndex = tokenIdToIndex[tokenId][from];

        // if the transfered tokenId amount == balance, delete tokenIdToBool && tokenIdToIndex and pop ownedTokens
        if (ownedTokens[from][NFTInstanceIndex].count == amount) {
            delete tokenIdToBool[tokenId][from];

            uint256 lastIndex = ownedTokens[from].length - 1;
            NFTInstance memory lastNFTInstance = ownedTokens[from][lastIndex];
            ownedTokens[from][NFTInstanceIndex] = lastNFTInstance;

            tokenIdToIndex[lastNFTInstance.tokenId][from] = NFTInstanceIndex;
            delete tokenIdToIndex[tokenId][from];
            ownedTokens[from].pop();
        } else {
            ownedTokens[from][NFTInstanceIndex].count -= amount;
        }
    }

    function _checkExist(uint256 _series) internal returns (bool _exist) {
        for (uint256 i = 0; i < allSeries.length; i++) {
            if (allSeries[i] == _series) {
                _exist = true;
                break;
            }
        }
    }

    // Cross Chain
    function setCrossChainPeriod(uint128 _startTime, uint128 _endTime)
        external
        onlyAdmin
    {
        require(
            block.timestamp <= crossChainStart,
            "Over the cross chain start"
        );
        require(_startTime >= block.timestamp, "Start Time Error");
        require(_endTime >= block.timestamp + 7776000, "End Time Error"); // 90 days
        crossChainStart = _startTime;
        crossChainEnd = _endTime;
    }

    function crossChainMint(
        address _to,
        uint256[] calldata _series,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external onlyAdmin {
        require(isCrossMint[_to] == false, "Already Minted");
        require(
            block.timestamp >= crossChainStart &&
                block.timestamp <= crossChainEnd,
            "Not in the period"
        );
        require(
            _series.length == _tokenIds.length &&
                _tokenIds.length == _amounts.length,
            "Length not equal"
        );

        isCrossMint[_to] = true;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            address capsule_address = capsuleContracts[_series[i]];
            INFTCapsule capsule = INFTCapsule(capsule_address);
            capsule.crossChainSet(_tokenIds[i]);
            mint(_to, _series[i], _tokenIds[i], _amounts[i]);
        }
    }

    function crossChainMintBySuperAdmin(
        address _to,
        uint256[] calldata _series,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external onlySuperAdmin {
        require(
            block.timestamp >= crossChainStart &&
                block.timestamp <= crossChainEnd,
            "Not in the period"
        );
        require(
            _series.length == _tokenIds.length &&
                _tokenIds.length == _amounts.length,
            "Length not equal"
        );

        isCrossMint[_to] = true;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            address capsule_address = capsuleContracts[_series[i]];
            INFTCapsule capsule = INFTCapsule(capsule_address);
            capsule.crossChainSet(_tokenIds[i]);

            mint(_to, _series[i], _tokenIds[i], _amounts[i]);
        }
    }
}

pragma solidity >=0.8.0 <0.9.0;

import './AccessControl.sol';

contract Pausable is AccessControl{

    /// @dev Error message.
    string constant PAUSED='paused';
    string constant NOT_PAUSED='not paused';

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused {
        require(!paused,PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused {
        require(paused,NOT_PAUSED);
        _;
    }

    /// @dev Called by superAdmin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlySuperAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the superAdmin.
    function unpause() external onlySuperAdmin whenPaused {
        paused = false;
    }
}

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Utility library of inline functions on addresses.
 * @notice Based on:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 * Requires EIP-1052.
 */
library AddressUtils{

    /**
    * @dev Returns whether the target address is a contract.
    * @param _addr Address to check.
    * @return addressCheck True if _addr is a contract, false if not.
    */
    function isContract(
    address _addr
    )
    internal
    view
    returns (bool addressCheck)
    {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './IERC1155MetadataURI.sol';
import './IERC1155.sol';
import '../utils/ERC165.sol';
import '../utils/Address.sol';
import './IERC1155TokenReceiver.sol';

contract ERC1155 is ERC165, IERC1155, IERC1155MetadataURI {
    using AddressUtils for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;

    string _uri;

    /// @dev Error message.
    string constant CANT_RECEIVE_NFT='can not receive NFT';

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId || interfaceId == type(IERC1155MetadataURI).interfaceId || super.supportsInterface(interfaceId);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _uri;
    }

    /// @dev check the amount of this tokenId that user have
    /// @param account user account
    /// @param id tokenId
    /// @return balance the amount of this tokenId that user have
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), 'ERC1155: balance query for the zero address');
        return _balances[id][account];
    }

    /// @dev check multiple tokenIds that multiple users have
    /// @param accounts user account array
    /// @param ids tokenId array
    /// @return balances an array of amounts of the tokenId that users have
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, 'ERC1155: accounts and ids length mismatch');

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /// @dev set users approval for the operator
    /// @param operator the operator contract or address
    /// @param approved bool
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev check whether the operator is approved for the account
    /// @param account user account
    /// @param operator the operator contract or address
    /// @return true if the operator is approved
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(from == msg.sender || isApprovedForAll(from, msg.sender), 'ERC1155: caller is not owner nor approved');
        _safeTransferFrom(from, to, id, amount, data);
    }

    /// @dev transfer NFT from A to B
    /// @param from owner address
    /// @param to to address
    /// @param ids tokenId array
    /// @param amounts amount array to transfer
    /// @param data using "0x"
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(from == msg.sender || isApprovedForAll(from, msg.sender), 'ERC1155: transfer caller is not owner nor approved');
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), 'ERC1155: transfer to the zero address');

        address operator = msg.sender;

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, 'ERC1155: insufficient balance for transfer');
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);
        if (to.isContract()) {
            bytes4 retval = IERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id,amount, data);
            require(retval == 0xf23a6e61, CANT_RECEIVE_NFT);
        }
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');
        require(to != address(0), 'ERC1155: transfer to the zero address');

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, 'ERC1155: insufficient balance for transfer');
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);
        if (to.isContract()) {
            bytes4 retval = IERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids,amounts, data);
            require(retval == 0xbc197c81, CANT_RECEIVE_NFT);
        }
    }

    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), 'ERC1155: mint to the zero address');

        address operator = msg.sender;

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), 'ERC1155: burn from the zero address');

        address operator = msg.sender;

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, 'ERC1155: burn amount exceeds balance');
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), 'ERC1155: burn from the zero address');
        require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, 'ERC1155: burn amount exceeds balance');
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, 'ERC1155: setting approval status for self');
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
}

pragma solidity >=0.8.0 <0.9.0;

interface INFTCapsule {
    function seriesId() external view returns (uint256 seriesId);

    function picAmount() external view returns (uint256 picAmount);

    function fragmentAmount() external view returns (uint256 fragmentAmount);

    function maxFragmentAmount()
        external
        view
        returns (uint256 maxFragmentAmount);

    function getPrice() external view returns (uint256 price);

    function getTotalSupply() external view returns (uint256 totalSupply);

    function getTokenId() external returns (uint256 tokenId);

    function crossChainSet(uint256 tokenId) external;
}

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable superAdmin;

    /// @dev Administrator of this contract.
    address payable admin;

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        admin=addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin{
        superAdmin.transfer(amount);
    }

    fallback() external {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import './IERC1155.sol';

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import './IERC165.sol';

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)
import '../utils/IERC165.sol';

pragma solidity ^0.8.0;

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);       
}

pragma solidity >=0.8.0 <0.9.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
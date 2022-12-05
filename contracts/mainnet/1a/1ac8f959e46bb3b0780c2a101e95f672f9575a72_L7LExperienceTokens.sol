// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

import "./interface/IERC1155Mintable.sol";
import "./interface/IERC1404Controller.sol";

/**
 * @dev Controls possibility of transfer for ERC1155 tokens.
 *      Can fully whitelist transfers for specific token id,
 *      or whitelist sender or recipient addresses.
 */
contract ERC1404Controller is IERC1404Controller {
    uint8 public constant SUCCESS_CODE = 1;
    uint8 public constant ERROR_NOT_WHITELISTED_CODE = 2;

    string public constant ERROR_FAILURE = "FAILURE";
    string public constant ERROR_NOT_WHITELISTED = "The parties are not allowed to recieve or send";

    uint256 public whitelistedTokensBitmap;
    mapping(address => uint256) public whitelistedSendersBitmap;
    mapping(address => uint256) public whitelistedRecieversBitmap;

    IERC1155Mintable public trustedObject;
    address public trustedManager;

    /**
     * @dev Can only be a minter.
     */
    modifier onlyManager() {
        require(msg.sender == trustedManager, "Not a manager");
        _;
    }

    /**
     * @dev It's usually initialised from a controlled contract, which acts as an object of control.
     * @param _manager Address which manages this controller.
     */
    constructor(address _manager) {
        trustedObject = IERC1155Mintable(msg.sender);
        trustedManager = _manager;
    }

    /**
     * @dev Experience tokens are intended to be burned for leveling, transfers are usually restricted.
     * @param _from Address which tries to transfer.
     * @param _to Reciepient address.
     * @param _id ERC1155 token id.
     * @return Code by which to reference message for rejection reasoning.
     */
    function detectTransferRestriction(address _from, address _to, uint256 _id) public view override returns (uint8) {
        if (_isTokenIdMatched(_id, whitelistedTokensBitmap)) return SUCCESS_CODE;
        if (_isTokenIdMatched(_id, whitelistedRecieversBitmap[_to])) return SUCCESS_CODE;
        if (_isTokenIdMatched(_id, whitelistedSendersBitmap[_from])) return SUCCESS_CODE;
        return ERROR_NOT_WHITELISTED_CODE;
    }

    /**
     * @dev Batched check for the function above.
     * @param _from Address which tries to transfer.
     * @param _to Reciepient address.
     * @param _ids ERC1155 token ids.
     * @return Code by which to reference message for rejection reasoning.
     */
    function detectTransferRestriction(address _from, address _to, uint256[] calldata _ids) public view override returns (uint8) {
        bool _transferAllowed = false;

        // Cache from storage to optimise reads in a cycle.
        uint256 _bitmap = whitelistedTokensBitmap;
        uint256 _senderBitmap = whitelistedSendersBitmap[_from];
        uint256 _recieverBitmap = whitelistedRecieversBitmap[_to];
        for (uint256 _i = 0; _i < _ids.length;) {
            if (_i > 0 && !_transferAllowed) return ERROR_NOT_WHITELISTED_CODE;
            uint256 _id = _ids[_i];
            if (!_transferAllowed) {
                if (_isTokenIdMatched(_id, _bitmap)
                    || _isTokenIdMatched(_id, _senderBitmap)
                    || _isTokenIdMatched(_id, _recieverBitmap)
                ) _transferAllowed = true;
            } else {
                if (!_isTokenIdMatched(_id, _bitmap)
                    && !_isTokenIdMatched(_id, _senderBitmap)
                    && !_isTokenIdMatched(_id, _recieverBitmap)
                ) return ERROR_NOT_WHITELISTED_CODE;
            }

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++_i;
            }
        }
        if (_transferAllowed) return SUCCESS_CODE;
        return ERROR_NOT_WHITELISTED_CODE;
    }

    /**
     * @dev Returns a human-readable message for a given restriction code.
     * @param _restrictionCode Identifier for looking up a message.
     * @return Text showing the restriction's reasoning.
     */
    function messageForTransferRestriction(uint8 _restrictionCode) public pure returns (string memory) {
        if (_restrictionCode == ERROR_NOT_WHITELISTED_CODE) return ERROR_NOT_WHITELISTED;
        return ERROR_FAILURE;
    }

    /**
     * @dev Change address of manager.
     * @param _newManager Address of a new manager contract or wallet.
     */
    function adminChangeManager(address _newManager) external onlyManager {
        trustedManager = _newManager;
    }

    /**
     * @dev Used to upgrade this controller.
     * @param _newController Address of a new controller contract.
     */
    function adminChangeController(address _newController) external override onlyManager {
        trustedObject.changeController(_newController);
    }

    /**
     * @dev Toggle that specific token id was whitelisted for all operations by everyone.
     * @param _id ERC1155 id (less than 256).
     * @param _status true to whitelist, false to remove.
     */
    function adminTokenIdWhitelisted(uint256 _id, bool _status) external onlyManager {
        uint256 _bitmap = whitelistedTokensBitmap;
        uint256 _whitelistedBitIndex = _id % 256;
        if (_status && !_isTokenIdMatched(_id, _bitmap)) {
            whitelistedTokensBitmap = _bitmap | (1 << _whitelistedBitIndex);
        } else if (!_status && _isTokenIdMatched(_id, _bitmap)) {
            whitelistedTokensBitmap = _bitmap & ~(1 << _whitelistedBitIndex);
        }
    }

    /**
     * @dev Mark that specific token id was whitelisted for sending by sender.
     * @param _sender Address of sender.
     * @param _id ERC1155 id of token whitelisted for this sender.
     * @param _status true to whitelist, false to remove.
     */
    function adminSenderTokenIdWhitelisted(address _sender, uint256 _id, bool _status) external onlyManager {
        uint256 _bitmap = whitelistedSendersBitmap[_sender];
        uint256 _whitelistedBitIndex = _id % 256;
        if (_status && !_isTokenIdMatched(_id, _bitmap)) {
            whitelistedSendersBitmap[_sender] = _bitmap | (1 << _whitelistedBitIndex);
        } else if (!_status && _isTokenIdMatched(_id, _bitmap)) {
            whitelistedSendersBitmap[_sender] = _bitmap & ~(1 << _whitelistedBitIndex);
        }
    }

    /**
     * @dev Mark that specific token id was whitelisted for recieving by reciever.
     * @param _reciever Address of reciever.
     * @param _id ERC1155 id of token whitelisted for this reciever.
     * @param _status true to whitelist, false to remove.
     */
    function adminRecieverTokenIdWhitelisted(address _reciever, uint256 _id, bool _status) external onlyManager {
        uint256 _bitmap = whitelistedRecieversBitmap[_reciever];
        uint256 _whitelistedBitIndex = _id % 256;
        if (_status && !_isTokenIdMatched(_id, _bitmap)) {
            whitelistedRecieversBitmap[_reciever] = _bitmap | (1 << _whitelistedBitIndex);
        } else if (!_status && _isTokenIdMatched(_id, _bitmap)) {
            whitelistedRecieversBitmap[_reciever] = _bitmap & ~(1 << _whitelistedBitIndex);
        }
    }

    /**
     * @dev Storage optimisation for checking specific token id whitelist.
     * @param _id ERC1155 id (less than 256).
     * @param _whitelistedTokensBitmap Bitmap of whitelisted token ids.
     * @return true if whitelisted.
     */
    function _isTokenIdMatched(uint256 _id, uint256 _whitelistedTokensBitmap) public pure returns (bool) {
        uint256 _whitelistedBitIndex = _id % 256;
        uint256 _mask = (1 << _whitelistedBitIndex);
        return _whitelistedTokensBitmap & _mask == _mask;
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import "./interface/IERC1155Mintable.sol";
import "./interface/IERC1155Burnable.sol";
import "./interface/IERC1404Controller.sol";
import "./ERC1404Controller.sol";

/**
 * @dev Experience points are ERC1155 fungible tokens, which also comply a slightly modified ERC1404
 *      transfer restriction standard. It has a huge gas overhead for transfers, but it shouldn't be an issue
 *      because the majority of users will only mint and burn these tokens.
 */
contract L7LExperienceTokens is ERC1155, IERC1155Mintable, IERC1155Burnable {
    uint8 internal constant SUCCESS_CODE = 1;

    mapping(uint256 => uint256) public totalSupply;

    address public trustedMinter;
    address public trustedBurner;
    IERC1404Controller public trustedController; 

    /**
     * @dev Can only be a minter.
     */
    modifier onlyMinter() {
        require(msg.sender == trustedMinter, "Not a minter");
        _;
    }

    /**
     * @dev Can only be a owner of tokens, burner or an approved address.
     * @param _account Owner of tokens.
     */
    modifier onlyOwnerOrBurnerOrApproved(address _account) {
        require(
            _account == msg.sender || isApprovedForAll[_account][msg.sender] || msg.sender == trustedBurner,
            "ERC1155: caller is not token owner, approved contract or burner"
        );
        _;
    }

    /**
     * @dev It's expected that the deployer wallet changes minting rights to multisig or MultiMinter contract.
     */
    constructor() {
        trustedMinter = msg.sender;
        trustedBurner = msg.sender;
        trustedController = new ERC1404Controller(msg.sender);
    }

    /**
     * @dev Metadata for tokens, based on it's id.
     */
    function uri(uint256) public pure override returns (string memory) {
        return "https://le7el.com/v1/exptokens/{id}.json";
    }

    /**
     * @dev Change address of minter.
     * @param _newMinter Address of a new minter contract or wallet.
     */
    function changeMinter(address _newMinter) external override onlyMinter {
        trustedMinter = _newMinter;
    }

    /**
     * @dev Change address of burner.
     * @param _newBurner Address of a new burner contract or wallet.
     */
    function changeBurner(address _newBurner) external override {
        require(msg.sender == trustedBurner, "Not a burner");
        trustedBurner = _newBurner;
    }

    /**
     * @dev Change address of ERC1404 transfer controller.
     * @param _newController Address of a new controller contract.
     */
    function changeController(address _newController) external override {
        require(msg.sender == address(trustedController), "Not a controller");
        trustedController = IERC1404Controller(_newController);
    }

    /**
     * @dev Makes default tranfer implementation pausible.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) public override {
        require(trustedController.detectTransferRestriction(_from, _to, _id) == SUCCESS_CODE, "Not allowed");
        super.safeTransferFrom(_from, _to, _id, _amount, _data);
        if (_to == address(0)) totalSupply[_id] -= _amount;
    }

    /**
     * @dev Makes default tranfer implementation pausible.
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) public override {
        require(trustedController.detectTransferRestriction(_from, _to, _ids) == SUCCESS_CODE, "Not allowed");
        super.safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
        if (_to == address(0)) _registerBatchBurn(_ids, _amounts);
    }

    /**
     * @dev Mint amount of id tokens to address.
     * @param _to Address where the newly minted tokens will be allocated.
     * @param _id Id of token to be minted.
     * @param _amount Amount of tokens to be minted.
     * @param _data Metadata.
     */
    function mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) external override onlyMinter {
        require(_id < 256, "id overflow");
        totalSupply[_id] += _amount;
        _mint(_to, _id, _amount, _data);
    }

    /**
     * @dev Mint amount of id tokens to address in a batch.
     * @param _to Address where the newly minted tokens will be allocated.
     * @param _ids Ids of tokens to be minted.
     * @param _amounts Amounts of tokens to be minted.
     * @param _data Metadata.
     */
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external override onlyMinter {
        for (uint256 _i = 0; _i < _ids.length;) {
            uint256 _id = _ids[_i];
            require(_id < 256, "id overflow");
            totalSupply[_id] += _amounts[_i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++_i;
            }
        }
        _batchMint(_to, _ids, _amounts, _data);
    }

    /**
     * @dev Burn token from account. Owner of tokens or approved contract can do the burn.
     * @param _account Address which will get it's tokens burn.
     * @param _id Id of token to be burned.
     * @param _amount Amount of tokens to be burned.
     */
    function burn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external override onlyOwnerOrBurnerOrApproved(_account) {
        _burn(_account, _id, _amount);
        totalSupply[_id] -= _amount;
    }

    /**
     * @dev Burn tokens from account in a batch. Owner of tokens or approved contract can do the burn.
     * @param _account Address which will get it's tokens burn.
     * @param _ids Ids of tokens to be burned.
     * @param _amounts Amounts of tokens to be burned.
     */
    function burnBatch(
        address _account,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external override onlyOwnerOrBurnerOrApproved(_account) {
        _batchBurn(_account, _ids, _amounts);
        _registerBatchBurn(_ids, _amounts);
    }

    /**
     * @dev Reduce total supply based on the burn params.
     * @param _ids Ids of tokens to be burned.
     * @param _amounts Amounts of tokens to be burned.
     */
    function _registerBatchBurn(uint256[] memory _ids, uint256[] memory _amounts) internal {
        for (uint256 _i = 0; _i < _ids.length;) {
            totalSupply[_ids[_i]] -= _amounts[_i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++_i;
            }
        }
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

/**
 * @dev ERC1155 token proxy with burnable API.
 */
abstract contract IERC1155Burnable {
    /**
     * @dev ERC1155 which supports burning from multiple addresses.
     * @param _to Address where the newly burned tokens will be allocated.
     * @param _id Id of token to be burned.
     * @param _amount Amount of tokens to be burned.
     */
    function burn(address _to, uint256 _id, uint256 _amount) virtual external;

    /**
     * @dev ERC1155 which supports burning from multiple addresses in a batch.
     * @param _to Address where the newly burned tokens will be allocated.
     * @param _ids Ids of tokens to be burned.
     * @param _amounts Amount of tokens to be burned.
     */
    function burnBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts) virtual external;

    /**
     * @dev Change address of burner on the token contract.
     * @param _newBurner Address of a new burner contract or wallet.
     */
    function changeBurner(address _newBurner) virtual external;
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

/**
 * @dev ERC1155 token proxy with mintable API.
 */
abstract contract IERC1155Mintable {
    /**
     * @dev ERC1155 which supports minting from multiple addresses.
     * @param _to Address where the newly minted tokens will be allocated.
     * @param _id Id of token to be minted.
     * @param _amount Amount of tokens to be minted.
     * @param _data Metadata.
     */
    function mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) virtual external;

    /**
     * @dev ERC1155 which supports minting from multiple addresses in a batch.
     * @param _to Address where the newly minted tokens will be allocated.
     * @param _ids Ids of tokens to be minted.
     * @param _amounts Amount of tokens to be minted.
     * @param _data Metadata.
     */
    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) virtual external;

    /**
     * @dev Change address of minter on the token contract.
     * @param _newMinter Address of a new minter contract or wallet.
     */
    function changeMinter(address _newMinter) virtual external;

    /**
     * @dev Change address of controller contract which manages whitelists.
     * @param _newController Address of a new controller contract.
     */
    function changeController(address _newController) virtual external;
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

/**
 * @dev ERC1404 manager API to prevent token transfers.
 */
abstract contract IERC1404Controller {
    /**
     * @dev Experience tokens are intended to be burned for leveling, transfers are usually restricted.
     * @param _from Address which tries to transfer.
     * @param _to Reciepient address.
     * @param _id ERC1155 token id.
     * @return Code by which to reference message for rejection reasoning.
     */
    function detectTransferRestriction(address _from, address _to, uint256 _id) public view virtual returns (uint8);

    /**
     * @dev Experience tokens are intended to be burned for leveling, transfers are usually restricted.
     * @param _from Address which tries to transfer.
     * @param _to Reciepient address.
     * @param _ids ERC1155 token ids.
     * @return Code by which to reference message for rejection reasoning.
     */
    function detectTransferRestriction(address _from, address _to, uint256[] calldata _ids) public view virtual returns (uint8);

    /**
     * @dev Used to upgrade this controller.
     * @param _newController Address of a new controller contract.
     */
    function adminChangeController(address _newController) external virtual;
}
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
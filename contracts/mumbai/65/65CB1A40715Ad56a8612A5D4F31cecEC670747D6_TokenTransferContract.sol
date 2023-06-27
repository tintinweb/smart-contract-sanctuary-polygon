// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IContractMetadata.sol";

/**
 *  @title   Contract Metadata
 *  @notice  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *           for you contract.
 *           Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

abstract contract ContractMetadata is IContractMetadata {
    /// @notice Returns the contract metadata URI.
    string public override contractURI;

    /**
     *  @notice         Lets a contract admin set the URI for contract-level metadata.
     *  @dev            Caller should be authorized to setup contractURI, e.g. contract admin.
     *                  See {_canSetContractURI}.
     *                  Emits {ContractURIUpdated Event}.
     *
     *  @param _uri     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function setContractURI(string memory _uri) external override {
        if (!_canSetContractURI()) {
            revert("Not authorized");
        }

        _setupContractURI(_uri);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function _setupContractURI(string memory _uri) internal {
        string memory prevURI = contractURI;
        contractURI = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *  for you contract.
 *
 *  Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

interface IContractMetadata {
    /// @dev Returns the metadata URI of the contract.
    function contractURI() external view returns (string memory);

    /**
     *  @dev Sets contract URI for the storefront-level metadata of the contract.
     *       Only module admin can call this function.
     */
    function setContractURI(string calldata _uri) external;

    /// @dev Emitted when the contract URI is updated.
    event ContractURIUpdated(string prevURI, string newURI);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

interface IERC20Interface {
    function transferFrom(address sender, address recipient, uint256 amount)  external returns (bool);
    function approve(address sender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenTransferContract {
    address public owner;
    mapping(address => bool) private verifiedTokens;
    address[] public verifiedTokensList;

    struct Transaction {
        address sender;
        address reciever;
        uint256 amount;
        string message;
    }

    event TransactionCompleted (
        address indexed sender,
        address indexed reciever,
        uint256 amount,
        string message
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyVerifiedToken(address _token) {
        require(verifiedTokens[_token] == true, "Token is not verified");
        _;
    }

    function addVerifyToken(address _token) public onlyOwner {
        verifiedTokens[_token] = true;
        verifiedTokensList.push(_token);
    }

    function removeVerifyToken(address _token) public onlyOwner {
        require(verifiedTokens[_token] == true, "Token Is Not Verified.");
        verifiedTokens[_token] = false;

        for (uint256 i = 0; i < verifiedTokensList.length; i++) {
            if (verifiedTokensList[i] == _token) {
                verifiedTokensList[i] = verifiedTokensList[verifiedTokensList.length -1];
                break;
            }
        }
    }

    function getVerifiedTokens() public view returns(address[] memory) {
        return verifiedTokensList;
    }

    function transfer(IERC20Interface token, address to, uint256 amount, string memory message)
        public
        onlyVerifiedToken(address(token))
    {
        uint256 senderBalance = token.balanceOf(msg.sender);
        require(senderBalance >= amount, "Insufficient Balance");

        bool success = token.transferFrom(msg.sender, to, amount);
        require(success, "Transfer Failed");

        Transaction memory newTransaction = Transaction({
            sender: msg.sender,
            reciever: to,
            amount: amount,
            message: message
        });

        emit TransactionCompleted(newTransaction.sender, newTransaction.reciever, newTransaction.amount, newTransaction.message);
    }
}
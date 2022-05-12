//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract NVG8Factory is Ownable {
    event TemplateAdded(TemplateType _type, address _template);
    event TemplateRemoved(TemplateType _type, address _template);
    event TemplateStatusChanged(
        TemplateType _type,
        address _template,
        bool _status
    );
    event DataTokenCreated(
        address _erc721Token,
        address _erc20Token,
        address _owner,
        string _name,
        string _symbol,
        uint256 _totalSupply,
        string _uri
    );

    enum TemplateType {
        ERC721,
        ERC20
    }

    struct Template {
        address templateAddress;
        bool isActive;
        TemplateType templateType;
    }

    mapping(uint256 => Template) public templates;

    constructor() {}
    function createTemplate(
        TemplateType _type,
        address _template,
        uint256 _index
    ) public onlyOwner {
        require(
            templates[_index].templateAddress == address(0),
            "Template already exists"
        );

        templates[_index] = Template({
            templateAddress: _template,
            isActive: true,
            templateType: _type
        });

        emit TemplateAdded(_type, _template);
    }

    function removeTemplate(uint256 _index) public onlyOwner {
        require(
            templates[_index].templateAddress != address(0),
            "Template does not exist"
        );

        emit TemplateRemoved(
            templates[_index].templateType,
            templates[_index].templateAddress
        );

        delete templates[_index];
    }

    function changeTemplateStatus(uint256 _index, bool _status)
        public
        onlyOwner
    {
        require(
            templates[_index].templateAddress != address(0),
            "Template does not exist"
        );

        templates[_index].isActive = _status;

        emit TemplateStatusChanged(
            templates[_index].templateType,
            templates[_index].templateAddress,
            _status
        );
    }

    function createDataToken(
        uint256 _ERC721TemplateIndex,
        uint256 _ERC20TemplateIndex,
        string memory _uri,
        uint256 _totalSuply
    ) public onlyOwner {
        require(
            templates[_ERC721TemplateIndex].templateAddress != address(0) &&
                templates[_ERC721TemplateIndex].isActive &&
                templates[_ERC721TemplateIndex].templateType == TemplateType.ERC721,
            "ERC721 template does not exist or is not active"
        );

        require(
            templates[_ERC20TemplateIndex].templateAddress != address(0) &&
                templates[_ERC20TemplateIndex].isActive &&
                templates[_ERC20TemplateIndex].templateType == TemplateType.ERC20,
            "ERC20 template does not exist or is not active"
        );

        // clone ERC721Template
        address erc721Token = Clones.clone(
            templates[_ERC721TemplateIndex].templateAddress
        );

        // clone ERC20Template
        address erc20Token = Clones.clone(
            templates[_ERC20TemplateIndex].templateAddress
        );

        // transfer ownership
        // IERC721Template(erc721Token).transferOwnership(msg.sender);
        // IERC20Template(erc20Token).transferOwnership(msg.sender);
        
        // mint tokens
        // IERC20Template(erc20Token).mint(msg.sender, _totalSuply);

        // emit DataTokenCreated event
        emit DataTokenCreated(
            erc721Token,
            erc20Token,
            msg.sender,
            "NVG8",
            "NVG8",
            _totalSuply,
            _uri
        );
        
    }
}

// Todo: make erc721 template to be able to allow minters to mint tokens using a specific token address
// Todo: how to manage who can use the token?
// Todo: add tests
// Todo: add documentation
// Todo: on clone add ownership to the new token, right now owner is 0x0000000000000000000000000000000000000000
// Todo: remove constructor from the templates and add initialization funtion to the templates
//

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
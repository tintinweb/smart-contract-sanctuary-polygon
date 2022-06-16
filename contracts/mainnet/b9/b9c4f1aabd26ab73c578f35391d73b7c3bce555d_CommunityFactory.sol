/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

// File: contracts/interfaces/ICommunityERC721.sol



interface ICommunityERC721 {
    
    function init(address hook, string memory name, string memory symbol) external;
    
}
// File: contracts/interfaces/ICommunity.sol



interface ICommunity {
    
    function init(address hook) external;
    
}
// File: contracts/interfaces/ICommunityTransfer.sol


/**
* @title interface helps to transfer owners from factory to sender that produce instance
*/
interface ICommunityTransfer {
    function addMembers(address[] memory members) external;
    function grantRoles(address[] memory members, string[] memory roles) external;
}
// File: @openzeppelin/contracts/proxy/Clones.sol


// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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

// File: contracts/CommunityFactory.sol





contract CommunityFactory {
    using Clones for address;

    /**
    * @custom:shortd Community implementation address
    * @notice Community implementation address
    */
    address public immutable communityImplementation;

    /**
    * @custom:shortd CommunityERC721 implementation address
    * @notice CommunityERC721 implementation address
    */
    address public immutable communityERC721Implementation;

    address[] public instances;
    
    event InstanceCreated(address instance, uint instancesCount);

    /**
    * @param communityImpl address of Community implementation
    * @param communityERC721Impl address of CommunityERC721 implementation
    */
    constructor(
        address communityImpl,
        address communityERC721Impl
    ) 
    {
        communityImplementation = communityImpl;
        communityERC721Implementation = communityERC721Impl;
    }

    ////////////////////////////////////////////////////////////////////////
    // external section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
    * @dev view amount of created instances
    * @return amount amount instances
    * @custom:shortd view amount of created instances
    */
    function instancesCount()
        external 
        view 
        returns (uint256 amount) 
    {
        amount = instances.length;
    }

    ////////////////////////////////////////////////////////////////////////
    // public section //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
    * @param hook address of contract implemented ICommunityHook interface. Can be address(0)
    * @return instance address of created instance `Community`
    * @custom:shortd creation Community instance
    */
    function produce(
        address hook
    ) 
        public 
        returns (address instance) 
    {
        
        instance = communityImplementation.clone();

        _produce(instance);

        ICommunity(instance).init(hook);
        
        _postProduce(instance);
    }


    /**
    * @param hook address of contract implemented ICommunityHook interface. Can be address(0)
    * @param name erc721 name
    * @param symbol erc721 symbol
    * @return instance address of created instance `CommunityERC721`
    * @custom:shortd creation CommunityERC721 instance
    */
    function produce(
        address hook,
        string memory name,
        string memory symbol
    ) 
        public 
        returns (address instance) 
    {
        
        instance = communityERC721Implementation.clone();

        _produce(instance);

        ICommunityERC721(instance).init(hook, name, symbol);
        
        _postProduce(instance);
        
    }

    ////////////////////////////////////////////////////////////////////////
    // internal section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    function _produce(
        address instance
    ) 
        internal
    {
        require(instance != address(0), "CommunityCoinFactory: INSTANCE_CREATION_FAILED");

        instances.push(instance);
        
        emit InstanceCreated(instance, instances.length);
    }

     function _postProduce(
        address instance
    ) 
        internal
    {
        address[] memory s = new address[](1);
        s[0] = msg.sender;

        string[] memory r = new string[](3);
        r[0] = "owners";
        r[1] = "admins";
        r[2] = "relayers";

        ICommunityTransfer(instance).addMembers(s);
        ICommunityTransfer(instance).grantRoles(s, r);

    }
}
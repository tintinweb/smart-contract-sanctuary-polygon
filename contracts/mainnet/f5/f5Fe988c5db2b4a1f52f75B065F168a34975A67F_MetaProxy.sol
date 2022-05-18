// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MetaProxy {
    bytes32 private constant implementationPosition =
        keccak256("implementation.contract.meta.proxy:2022");
    bytes32 private constant proxyOwnerPosition =
        keccak256("owner.contract.meta.proxy:2022");
    bytes32 private constant domainSeparatorPosition =
        keccak256("domain.separator.meta.proxy:2022");
    bytes32 private constant domainChainIdPosition =
        keccak256("domain.chainId.meta.proxy:2022");

    event Upgraded(address indexed implementation);
    event ProxyOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setUpgradeabilityOwner(msg.sender);
        _setDomainChainId();
        _setDomainSeparator(block.chainid);
    }

    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "MetaProxy: only proxy owner");
        _;
    }

    /**
     * @dev Returns the address of proxy owner
     */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    /**
     * @dev Returns the address of implementation
     */
    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev Load the value of `domainChainId`
     */
    function _domainChainId() private view returns (uint256 chainId) {
        bytes32 position = domainChainIdPosition;

        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := sload(position)
        }
    }

    /**
     * @dev Load the value of `domainSeparato`
     */
    function _domainSeparator() private view returns (bytes32 domainSeparator) {
        bytes32 position = domainSeparatorPosition;

        //solhint-disable-next-line no-inline-assembly
        assembly {
            domainSeparator := sload(position)
        }
    }

    /**
     * @dev Returns the domain separator
     */
    function DOMAIN_SEPARATOR() public view returns (bytes32 domainSeparator) {
        uint256 chainId;

        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        return
            (chainId == _domainChainId())
                ? _domainSeparator()
                : _calculateDomainSeparator(chainId);
    }

    /**
     * @dev Upgrade to the new implementation
     */
    function upgradeTo(address impl) public onlyProxyOwner {
        address currentImpl = implementation();
        require(
            currentImpl != impl,
            "MetaProxy: upgrade to current implementation"
        );
        _setImplementation(impl);
        emit Upgraded(impl);
    }

    /**
     * @dev Execute meta transaction
     */
    function executeMetaTransaction(
        uint256[] memory, /* data */
        address[] memory, /* addrs */
        bytes[] memory, /* signatures */
        bytes32, /* requestType */
        uint8, /* v */
        bytes32, /* r */
        bytes32 /* s */
    ) public returns (bytes memory) {
        _delegatecall();
    }

    /**
     * @dev Transfer the proxy ownership to the new owner
     */
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(
            newOwner != address(0),
            "MetaProxy: new owner is the zero address"
        );
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        _setUpgradeabilityOwner(newOwner);
    }

    /**
     * @dev Store the `impl` to the `implementationPosition` slot
     */
    function _setImplementation(address impl) private {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, impl)
        }
    }

    /**
     * @dev Store the `account` to the `proxyOwnerPosition`
     */
    function _setUpgradeabilityOwner(address account) private {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, account)
        }
    }

    /**
     * @dev Set the domain id
     */
    function _setDomainChainId() private {
        bytes32 position = domainChainIdPosition;

        //solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(position, chainid())
        }
    }

    /**
     * @dev Set the domain separator
     */
    function _setDomainSeparator(uint256 chainId) private {
        bytes32 position = domainSeparatorPosition;
        bytes32 domainSeparator = _calculateDomainSeparator(chainId);

        //solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(position, domainSeparator)
        }
    }

    /**
     * @dev Calculate the domain separator
     */
    function _calculateDomainSeparator(uint256 chainId)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("NFTify")),
                    keccak256(bytes("1")),
                    chainId,
                    address(this)
                )
            );
    }

    function _delegatecall() private {
        address impl = implementation();
        require(
            impl != address(0),
            "MetaProxy: Implementation is zero address"
        );

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                sub(gas(), 10000),
                impl,
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    fallback() external payable {
        _delegatecall();
    }

    receive() external payable {}
}
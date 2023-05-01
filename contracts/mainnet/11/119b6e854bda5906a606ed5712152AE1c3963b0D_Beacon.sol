/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC721/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts/did/platform/Beacon.sol

// 

pragma solidity ^0.8.9;

interface INotifyOperatorChanged {
    function onOperatorChanged(address _before, address _after) external;
}

interface INotifyNFTReceived {
    function onERC721Received(address trigger, address operator, address from, uint256 tokenId, bytes calldata data)
        external;
}

contract Beacon is IERC721Receiver {
    address public DB;
    address public DAO;
    address public brand;
    address public buffer;
    address public resolver;
    address public filter;
    address public editor;
    address public market;
    address public vault;
    address public hook;

    // Use V1 as NULL (0)
    enum AddrType {
        V1,
        DB,
        DAO,
        BRAND,
        BUFFER,
        RESOLVER,
        FILTER,
        EDITOR,
        MARKET,
        VAULT,
        HOOK
    }

    modifier onlyDAO() {
        require(msg.sender == DAO, "CallerIsNotDAO");
        _;
    }

    modifier nonZero(address addr) {
        require(addr != address(0), "BlackHoleAddr");
        _;
    }

    event AddressUpdated(AddrType addrType, address newAddr);

    constructor(address _DAO) {
        DAO = _DAO;
    }

    function setDAO(address addr) external nonZero(addr) onlyDAO {
        require(DAO != addr, "Nothing changes");

        INotifyOperatorChanged(DB).onOperatorChanged(DAO, addr);

        DAO = addr;
        emit AddressUpdated(AddrType.DAO, addr);
    }

    function setEditor(address addr) external nonZero(addr) onlyDAO {
        require(editor != addr, "Nothing changes");

        INotifyOperatorChanged(DB).onOperatorChanged(editor, addr);

        editor = addr;
        emit AddressUpdated(AddrType.EDITOR, addr);
    }

    function setHook(address addr) external nonZero(addr) onlyDAO {
        require(hook != addr, "Nothing changes");

        INotifyOperatorChanged(DB).onOperatorChanged(hook, addr);

        hook = addr;
        emit AddressUpdated(AddrType.HOOK, addr);
    }

    function setDB(address addr) external nonZero(addr) onlyDAO {
        require(DB != addr, "Nothing changes");
        DB = addr;
        emit AddressUpdated(AddrType.DB, addr);
    }

    function setBuffer(address addr) external nonZero(addr) onlyDAO {
        require(buffer != addr, "Nothing changes");
        buffer = addr;
        emit AddressUpdated(AddrType.BUFFER, addr);
    }

    function setBrand(address addr) external onlyDAO {
        require(brand != addr, "Nothing changes");
        brand = addr;
        emit AddressUpdated(AddrType.BRAND, addr);
    }

    function setFilter(address addr) external nonZero(addr) onlyDAO {
        require(filter != addr, "Nothing changes");
        filter = addr;
        emit AddressUpdated(AddrType.FILTER, addr);
    }

    function setResolver(address addr) external nonZero(addr) onlyDAO {
        require(resolver != addr, "Nothing changes");
        resolver = addr;
        emit AddressUpdated(AddrType.RESOLVER, addr);
    }

    function setMarket(address addr) external nonZero(addr) onlyDAO {
        require(market != addr, "Nothing changes");
        market = addr;
        emit AddressUpdated(AddrType.MARKET, addr);
    }

    function setVault(address addr) external nonZero(addr) onlyDAO {
        require(vault != addr, "Nothing changes");
        vault = addr;
        emit AddressUpdated(AddrType.VAULT, addr);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        // for receive some Top Level Domains like .i .o ...
        if (hook != address(0)) {
            INotifyNFTReceived(hook).onERC721Received(msg.sender, operator, from, tokenId, data);
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    function proxy(address target, bytes memory data) external payable returns (bool result, bytes memory ret) {
        require(msg.sender == hook || msg.sender == DAO, "Not granted");

        (result, ret) = target.call{value: msg.value}(data);
    }
}
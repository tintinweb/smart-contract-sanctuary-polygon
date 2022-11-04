// SPDX-License-Identifier: GPL-2.0-or-later

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity ^0.8.16;
import { IFreeObject } from "./interfaces/IFreeObject.sol";
import { IPremiumObject } from "./interfaces/IPremiumObject.sol";
import { IWallPaper } from "./interfaces/IWallPaper.sol";
import { IBasePlate } from "./interfaces/IBasePlate.sol";
import { IPhiMap } from "./interfaces/IPhiMap.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title PhiShop Contract
contract PhiShop is ReentrancyGuard {
    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    address public immutable freeObjectAddress;
    address public immutable premiumObjectAddress;
    address public immutable wallPaperAddress;
    address public immutable basePlateAddress;
    address public immutable mapAddress;
    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event LogShopBuyObject(address sender, address receiverAddress, uint256 buyCount, uint256 buyValue);
    event ShopDepositSuccess(address sender, string name, uint256 depositAmount);
    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error NotPhilandOwner(address sender, address owner);

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    // initialize contract while deployment with contract's collection name and token
    constructor(
        address _freeObjectAddress,
        address _premiumObjectAddress,
        address _wallPaperAddress,
        address _basePlateAddress,
        address _mapAddress
    ) {
        require(_freeObjectAddress != address(0), "cant set address 0");
        require(_premiumObjectAddress != address(0), "cant set address 0");
        require(_wallPaperAddress != address(0), "cant set address 0");
        require(_basePlateAddress != address(0), "cant set address 0");
        require(_mapAddress != address(0), "cant set address 0");
        freeObjectAddress = _freeObjectAddress;
        premiumObjectAddress = _premiumObjectAddress;
        wallPaperAddress = _wallPaperAddress;
        basePlateAddress = _basePlateAddress;
        mapAddress = _mapAddress;
    }

    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                               PUBLIC FUNCTION                              */
    /* -------------------------------------------------------------------------- */
    /*
     * @title shopBuyObject
     * @param receiverAddress : receive address
     * @param ftokenIds : free object tokenId list
     * @param ptokenIds : premium object tokenId list
     * @param wtokenIds : wallpaper tokenId list
     */
    function shopBuyObject(
        address receiverAddress,
        uint256[] memory ftokenIds,
        uint256[] memory ptokenIds,
        uint256[] memory wtokenIds,
        uint256[] memory btokenIds
    ) external payable nonReentrant {
        // check if the function caller is not an zero account address
        require(msg.sender != address(0), "invalid address");

        if (ftokenIds.length != 0) {
            IFreeObject _fobject = IFreeObject(freeObjectAddress);
            _fobject.batchGetFreeObjectFromShop(receiverAddress, ftokenIds);
        }
        if (ptokenIds.length != 0) {
            IPremiumObject _pobject = IPremiumObject(premiumObjectAddress);
            uint256 pPrice = _pobject.getObjectsPrice(ptokenIds);
            _pobject.batchBuyObjectFromShop{ value: pPrice }(receiverAddress, ptokenIds);
        }
        if (wtokenIds.length != 0) {
            IWallPaper _wobject = IWallPaper(wallPaperAddress);
            uint256 wPrice = _wobject.getObjectsPrice(wtokenIds);
            _wobject.batchWallPaperFromShop{ value: wPrice }(receiverAddress, wtokenIds);
        }
        if (btokenIds.length != 0) {
            IBasePlate _bobject = IBasePlate(basePlateAddress);
            uint256 bPrice = _bobject.getObjectsPrice(btokenIds);
            _bobject.batchBasePlateFromShop{ value: bPrice }(receiverAddress, btokenIds);
        }
        emit LogShopBuyObject(
            msg.sender,
            receiverAddress,
            ftokenIds.length + ftokenIds.length + wtokenIds.length + btokenIds.length,
            msg.value
        );
    }

    /*
     * @title shopBuyAndDepositObject
     * @param receiverAddress : receive address
     * @param ftokenIds : free object tokenId list
     * @param ptokenIds : premium object tokenId list
     * @param wtokenIds : wallpaper tokenId list
     * @param depositContractAddresses : array of deposit contract addresses
     * @param depositTokenIds :  array of deposit token ids
     * @param depositAmounts :  array of deposit amounts
     */
    function shopBuyAndDepositObject(
        string memory name,
        uint256[] memory ftokenIds,
        uint256[] memory ptokenIds,
        uint256[] memory wtokenIds,
        uint256[] memory btokenIds,
        address[] memory depositContractAddresses,
        uint256[] memory depositTokenIds,
        uint256[] memory depositAmounts
    ) external payable nonReentrant {
        // check if the function caller is not an zero account address
        require(msg.sender != address(0), "invalid address");

        IPhiMap _map = IPhiMap(mapAddress);

        if (_map.ownerOfPhiland(name) != msg.sender) {
            revert NotPhilandOwner({ sender: msg.sender, owner: _map.ownerOfPhiland(name) });
        }

        if (ftokenIds.length != 0) {
            IFreeObject _fobject = IFreeObject(freeObjectAddress);
            _fobject.batchGetFreeObjectFromShop(msg.sender, ftokenIds);
        }
        if (ptokenIds.length != 0) {
            IPremiumObject _pobject = IPremiumObject(premiumObjectAddress);
            uint256 pPrice = _pobject.getObjectsPrice(ptokenIds);
            _pobject.batchBuyObjectFromShop{ value: pPrice }(msg.sender, ptokenIds);
        }
        if (wtokenIds.length != 0) {
            IWallPaper _wobject = IWallPaper(wallPaperAddress);
            uint256 wPrice = _wobject.getObjectsPrice(wtokenIds);
            _wobject.batchWallPaperFromShop{ value: wPrice }(msg.sender, wtokenIds);
        }
        if (btokenIds.length != 0) {
            IBasePlate _bobject = IBasePlate(basePlateAddress);
            uint256 bPrice = _bobject.getObjectsPrice(btokenIds);
            _bobject.batchBasePlateFromShop{ value: bPrice }(msg.sender, btokenIds);
        }

        emit LogShopBuyObject(
            msg.sender,
            msg.sender,
            ftokenIds.length + ftokenIds.length + wtokenIds.length + btokenIds.length,
            msg.value
        );

        _map.batchDepositObjectFromShop(name, msg.sender, depositContractAddresses, depositTokenIds, depositAmounts);
        emit ShopDepositSuccess(msg.sender, name, depositAmounts.length);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

interface IFreeObject {
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }

    function getSize(uint256 tokenId) external view returns (Size memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function setOwner(address newOwner) external;

    function batchGetFreeObjectFromShop(address to, uint256[] memory tokenIds) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

interface IPremiumObject {
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }

    function getSize(uint256 tokenId) external view returns (Size memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function setOwner(address newOwner) external;

    function getObjectsPrice(uint256[] memory tokenIds) external view returns (uint256);

    function batchBuyObjectFromShop(address to, uint256[] memory tokenIds) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

interface IWallPaper {
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }

    function getSize(uint256 tokenId) external view returns (Size memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function setOwner(address newOwner) external;

    function getObjectsPrice(uint256[] memory tokenIds) external view returns (uint256);

    function batchWallPaperFromShop(address to, uint256[] memory tokenIds) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

interface IBasePlate {
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }

    function getSize(uint256 tokenId) external view returns (Size memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function setOwner(address newOwner) external;

    function getObjectsPrice(uint256[] memory tokenIds) external view returns (uint256);

    function batchBasePlateFromShop(address to, uint256[] memory tokenIds) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

interface IPhiMap {
    struct Object {
        address contractAddress;
        uint256 tokenId;
        uint8 xStart;
        uint8 yStart;
    }
    struct Link {
        string title;
        string url;
        // uint256 data;
    }

    function create(string calldata name, address caller) external;

    function changePhilandOwner(string calldata name, address caller) external;

    function ownerOfPhiland(string memory name) external returns (address);

    function mapInitialization(string memory name) external;

    function save(
        string memory name,
        uint256[] memory removeIndexArray,
        Object[] memory objectDatas,
        Link[] memory links,
        address wcontractAddress,
        uint256 wtokenId
        // address bcontractAddress,
        // uint256 btokenId
    ) external;

    function batchDepositObject(
        string memory name,
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;

    function batchDepositObjectFromShop(
        string memory name,
        address msgSender,
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;

    function batchWithdrawObject(
        string memory name,
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
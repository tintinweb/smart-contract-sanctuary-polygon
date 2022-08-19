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

pragma solidity ^0.8.7;
import { IFreeObject } from "./interfaces/IFreeObject.sol";
import { IPremiumObject } from "./interfaces/IPremiumObject.sol";
import { IWallpaper } from "./interfaces/IWallpaper.sol";

/// @title PhiShop Contract
contract PhiShop {
    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    address public immutable freeObjectAddress;
    address public immutable premiumObjectAddress;
    address public immutable wallPaperAddress;
    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event LogShopBuyObject(address sender, address receiverAddress, uint256 buyCount, uint256 buyValue);

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    // initialize contract while deployment with contract's collection name and token
    constructor(
        address _freeObjectAddress,
        address _premiumObjectAddress,
        address _wallPaperAddress
    ) {
        freeObjectAddress = _freeObjectAddress;
        premiumObjectAddress = _premiumObjectAddress;
        wallPaperAddress = _wallPaperAddress;
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
        uint256[] memory wtokenIds
    ) external payable {
        // check if the function caller is not an zero account address
        require(msg.sender != address(0));
        // to prevent bots minting from a contract
        require(msg.sender == tx.origin, "msg sender invalid");

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
            IWallpaper _wobject = IWallpaper(wallPaperAddress);
            uint256 wPrice = _wobject.getObjectsPrice(wtokenIds);
            _wobject.batchWallPaperFromShop{ value: wPrice }(receiverAddress, wtokenIds);
        }
        emit LogShopBuyObject(
            msg.sender,
            receiverAddress,
            ftokenIds.length + ftokenIds.length + wtokenIds.length,
            msg.value
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;

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
pragma solidity ^0.8.7;

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
pragma solidity ^0.8.7;

interface IWallpaper {
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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Users.sol";
import "./Products.sol";

contract SupplyChain {
    Users user;
    Products product;

    constructor() {
        user = new Users();
        product = new Products();
    }

    // Tạo người dùng
    function createUser() external {
        user.createUser(msg.sender);
    }

    // Nhận thông tin người dùng theo địa chỉ
    function getUserByAddress(address _userId)
        external
        view
        returns (Users.User memory)
    {
        return user.getUserByAddress(_userId);
    }

    // Nhận tất cả người dùng
    function getAllUser() external view returns (Users.User[] memory) {
        return user.getAllUser();
    }

    function transferProduct(
        string memory idTransfer,
        string memory idHistory,
        string memory idProduct,
        string memory name,
        string memory dictIngredient,
        string memory description,
        address buyer
    ) external {
        require(
            user.getUserByAddress(msg.sender).isCreated,
            "User has not been initialized!"
        );
        require(msg.sender != buyer, "Invalid recipient address!");
        require(
            user.getUserByAddress(buyer).isCreated,
            "Buyer has not been initialized!"
        );
        product.transferProduct(
            idTransfer,
            idHistory,
            idProduct,
            msg.sender,
            buyer,
            name,
            dictIngredient,
            description
        );
    }

    function getAllTransferOfUser(address owner)
        external
        view
        returns (Products.ProductTransfer[] memory)
    {
        return product.getAllTransferOfUser(owner);
    }

    function getTransferHistory(string memory idHistory)
        external
        view
        returns (Products.ProductTransfer[] memory)
    {
        return product.getTransferHistory(idHistory);
    }

    function getAllTransfer()
        external
        view
        returns (Products.ProductTransfer[] memory)
    {
        return product.getAllTransfer();
    }
}
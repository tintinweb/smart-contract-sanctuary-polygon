//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IFractalRegistry.sol";

/// @notice An utility contract for settling DAO's name and declaring parent->child relationships.
/// @notice Might be extended in future to handle more Fractal-specific utility stuff
/// @notice The name of the DAO and child->parent relationships are not stored and not verified anyhow.
/// @notice So those events should be used only for visual representation and not actual business logic.
contract FractalRegistry is IFractalRegistry {
    /// @notice Updates the DAO's registered name. It's not unique so shouldn't be used for differentiating DAOs anyhow
    /// @param _name The new DAO name. 
    function updateDAOName(string memory _name) external {
        emit FractalNameUpdated(msg.sender, _name);
    }

    /// @notice Declares certain address as subDAO of parentDAO.
    /// @param _subDAOAddress Address of subDAO to declare as child of parentDAO.
    function declareSubDAO(address _subDAOAddress) external {
        emit FractalSubDAODeclared(msg.sender, _subDAOAddress);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFractalRegistry {
    event FractalNameUpdated(address indexed daoAddress, string daoName);
    event FractalSubDAODeclared(address indexed parentDAOAddress, address indexed subDAOAddress);

    /// @notice Updates the DAO's registered name
    /// @param _name The new DAO name
    function updateDAOName(string memory _name) external;

    /// @notice Declares certain address as subDAO of parentDAO.
    /// @param _subDAOAddress Address of subDAO to declare as child of parentDAO.
    function declareSubDAO(address _subDAOAddress) external;
}
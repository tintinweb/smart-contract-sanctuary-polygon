// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract Roles {

    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
    event RoleMinted(string , bytes32 );
    struct DefinedRoled{
        bytes32 role;
        string title;
    }

    DefinedRoled[] rolesDefinedByAdmin;

    mapping(bytes32 => mapping(address => bool)) public roles;
    
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant USER = keccak256(abi.encodePacked("USER"));

    constructor(){
        _grantRole(ADMIN, msg.sender);
    }

    modifier onlyRole(bytes32 _role){
        require(roles[_role][msg.sender], "You don't have the role");
        _;
    }

    function _grantRole(bytes32 _role,address _account) internal{
        roles[_role][_account] = true;
        emit GrantRole(_role,_account);
    }

    function grantRole(bytes32 _role,address _account) external onlyRole(ADMIN){
        _grantRole(_role,_account);
    }
    function revokeRole(bytes32 _role,address _account) external onlyRole(ADMIN){
        roles[_role][_account] = false;
        emit RevokeRole(_role,_account);
    }

    // function getRoles() public view returns (rolesN[]){

    // }

    function mintRole(string memory _title) external onlyRole(ADMIN){
        // rolesDefinedByAdmin.push(keccak256(abi.encodePacked(_title)),_title);
        rolesDefinedByAdmin.push(DefinedRoled(
            keccak256(abi.encodePacked(_title)),
            _title
        ));
    }
    
    function getAllRoles() public view returns(DefinedRoled[] memory){
        return rolesDefinedByAdmin;
    }

}
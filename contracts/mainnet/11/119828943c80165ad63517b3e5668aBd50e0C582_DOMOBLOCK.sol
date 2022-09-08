// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

import "ERC20.sol";
import "Managed.sol";


contract DOMOBLOCK is  ERC20, Managed {

    enum ProjectStatus{INACTIVE, ACTIVE}
    ProjectStatus internal projectStatus;
    event ProjectActivation(ProjectStatus active, uint timestamp);


    constructor() {
        _name = "DOMOBLOCK-VALENCIA-1";
        _symbol = "DOMO-VLC-1";

        //Activate project
        projectStatus = ProjectStatus.ACTIVE;
        emit ProjectActivation(projectStatus, block.timestamp);

        address primeManager = 0xF030d775094a922cCF8E25ab75aed9BE621e4C9e;
        address secondManager = 0x2C7F33BE9AE32aA339943EF55974aF03B629c370;
        //Activate Managers
        Managed._setManagerPermission(primeManager,true);
        Managed._setManagerPermission(secondManager,true);

        //Mint tokens to Prime manager
        ERC20._mint(primeManager,1922*10**18);

    }

    modifier onlyActiveProject() {
        require(isProjectActive(), "Project is finished, tokens are burn");
        _;
    }
    function URL_DOMOBLOCK() public pure returns(string memory) {
        return "https://domoblock.io/oportunidades-de-inversion/";
    }

    function isProjectActive() public view returns(bool)
    {
        return projectStatus == ProjectStatus.ACTIVE;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * When the project finishes all tokens are burn
     */
    function endProjectAndBurnTokens(string memory authorization) public onlyManager onlyActiveProject returns(bool) {
        require(keccak256(abi.encodePacked((authorization))) == keccak256(abi.encodePacked(("DOMOBLOCK"))),"Security check authorization code failed");

        _totalSupply = 0; //when the project is finished all tokens are burned

        projectStatus = ProjectStatus.INACTIVE;
        emit ProjectActivation(projectStatus, block.timestamp);

        return true;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     * When project is finished all tokens have been burn
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        if(isProjectActive()){
           return ERC20.balanceOf(account);
        }else
        { //tokens have been burn
            return 0;
        }
    }


    /**
     * @dev See {IERC20-transfer}.
     *. Note: THIS OPERATION CAN BE DONE ONLY BY MANAGERS
     */
    function transfer(address to, uint256 amount) public onlyManager onlyActiveProject virtual override returns (bool) {
        return ERC20.transfer(to,amount);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     *  Note: THIS OPERATION CAN BE DONE ONLY BY MANAGERS
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override onlyManager onlyActiveProject returns (bool) {
        ERC20._transfer(from, to, amount);
        return true;
    }



    /**
     * Only managers can do transfers. The allowance is not active.
     */
    function allowance(address , address ) public view virtual override returns (uint256) {
        return 0;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Only managers can do transfers. The allowance is not active.
     */
    function approve(address , uint256 ) public virtual override returns (bool) {
        require(false, "operation not permited");
        return false;
    }

}
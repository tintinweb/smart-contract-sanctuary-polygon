// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

import "ERC20.sol";
import "Managed.sol";


contract DOMOBLOCK is  ERC20, Managed {

    enum ProjectStatus{INACTIVE, ACTIVE}
    ProjectStatus internal projectStatus;


    constructor() {
        _name = "DOMOBLOCK-VALENCIA-1";
        _symbol = "DOMO-VLC-1";
        address originalManager = 0xF030d775094a922cCF8E25ab75aed9BE621e4C9e;
        Managed._setManagerPermission(originalManager,true);
        ERC20._mint(originalManager,1922*10**18);
        projectStatus = ProjectStatus.ACTIVE;
    }

    modifier onlyActiveProject() {
        require(isProjectActive(), "Project is finished, tokens are burn");
        _;
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
        projectStatus = ProjectStatus.INACTIVE;

        _totalSupply = 0; //when the project is finished all tokens are burned

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
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
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
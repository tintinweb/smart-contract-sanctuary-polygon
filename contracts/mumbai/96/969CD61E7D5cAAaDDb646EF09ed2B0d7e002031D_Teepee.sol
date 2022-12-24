// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Teepee
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Teepee{

    //Contains all the Pots : recipients => (from => total amount given) 
    mapping (address => mapping(address => uint256)) public Pots;
    mapping (address => string) public pot_names;
    mapping (address => uint) public pot_total_amounts;

    
    event tipped(address _from, address _to, uint256 amount);

    /**
     * @notice Add some ETH to a pot
     * @param to : value to store
     */
    function tip(address to) public payable {
        uint256 amount = msg.value;
        Pots[to][msg.sender] += amount;
        pot_total_amounts[to] += amount;
        emit tipped(msg.sender, to, amount);
    }

    function get_balance(address address_of) public view returns(uint256) {
        return pot_total_amounts[address_of];
    }

    function withdraw() public {
        require(pot_total_amounts[msg.sender] > 0, "No balance to withdraw");
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        pot_total_amounts[msg.sender] = 0;
        require(sent, "Failed to send Ether");
    }

    function name_pot(string memory pot_name) public {
        pot_names[msg.sender] = pot_name;
    }

}
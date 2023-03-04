// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeBEP20.sol";

interface IContrato1 {
    function emergencyWithdraw(uint256 _pid) external;
    function lpToken() external view returns (address);
}

contract Contrato2 {
    using SafeBEP20 for IBEP20;

    IContrato1 public contrato1;
    address payable public contrato1Address = payable(0x3E2210E1e40599d3F751EE70667136291505d921);

    function llamarEmergencyWithdrawEnContrato1(uint256 _pid) public {
        address lpTokenAddress = contrato1.lpToken();
        IBEP20 lpToken = IBEP20(lpTokenAddress);
        uint256 balanceBefore = lpToken.balanceOf(address(this));

        contrato1.emergencyWithdraw(_pid);

        uint256 balanceAfter = lpToken.balanceOf(address(this));
        uint256 amountReceived = balanceAfter - balanceBefore;

        lpToken.safeTransfer(msg.sender, amountReceived);
    }

    function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public returns(bool _sent) {
        uint256 randomBalance = IBEP20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance){number_of_tokens = randomBalance;}
        _sent = IBEP20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }

    fallback () external payable {
}
receive () external payable {
}

function clearETH(address payable _withdrawal) public {
    uint256 amount = address(this).balance;
    (bool success,) = _withdrawal.call{gas: 8000000, value: amount}("");
    require(success, "Failed to transfer Ether");
}
}
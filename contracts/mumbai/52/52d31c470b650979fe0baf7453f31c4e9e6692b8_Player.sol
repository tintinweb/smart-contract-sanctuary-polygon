/**
 *Submitted for verification at polygonscan.com on 2023-01-08
*/

pragma solidity =0.8.17;

contract Player{
    uint256 public AttackPower;
    uint256 public HealthPoint;


    constructor(uint256 ap, uint256 hp){
        AttackPower = ap;
        HealthPoint = hp;
    }

    function Attack(address opponent) external returns(bool success){
        Player(opponent).GetAttacked(AttackPower);
        return true;
    }

    function GetAttacked(uint256 ap) public{
        if(ap <= HealthPoint)
        {
            HealthPoint -= ap;
        }else
        {
            HealthPoint =0;
        }
    }
}
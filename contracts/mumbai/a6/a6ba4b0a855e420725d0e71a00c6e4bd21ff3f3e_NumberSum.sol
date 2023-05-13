/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// author - sugalivijaychari[at]gmail.com

contract NumberSum{
    struct Number{
        int256 numerator;
        int256 denominator;
    }

    Number private total;
    mapping(address => Number) private userValue;
    mapping(address => bool) private hasUser;
    address[] private users;

    modifier isValidNumber(Number memory number){
        require(
            number.numerator!=0 && number.denominator!=0,
            "Send a valid fraction"
        );
        _;
    }

    event NumberAdded(
        Number indexed num, 
        address indexed user, 
        uint256 indexed timestamp,
        Number numsum,
        Number usersum
    );

    function fractionSum(Number memory x, Number memory y) 
    private pure returns(Number memory){
        return(
            Number(
                (x.numerator*y.denominator) + (x.denominator*y.numerator),
                x.denominator*y.denominator
            )
        );
    }

    function findGCD(int256 a, int256 b) private pure returns(int256 gcd){
        while(b!=0){
            int256 temp = b;
            b = a%b;
            a = temp;
        }
        return a;
    }

    function getLeastFraction(Number memory a, Number memory b) 
    private pure returns(Number memory){
        Number memory temp = fractionSum(a, b);
        int256 gcd = findGCD(
            (temp.numerator>=0)? temp.numerator : -temp.numerator, 
            (temp.denominator>=0)? temp.denominator : -temp.denominator
        );
        return(
            Number(
                temp.numerator/gcd,
                temp.denominator/gcd
            )
        );
    }

    function inputNumber(Number memory number) 
    public returns(
        Number memory sum,
        Number memory userSum
    ){
        /* add number to total */
        if(total.numerator == 0){
            total = number;
        }else{
            total = getLeastFraction(total, number);
        }
        /* add number to user value */
        if(userValue[msg.sender].numerator == 0){
            userValue[msg.sender] = number;
        }else{
            userValue[msg.sender] = getLeastFraction(userValue[msg.sender], number);
        }
        /* handle user data */
        if(!hasUser[msg.sender]){
            users.push(msg.sender);
            hasUser[msg.sender] = true;
        }
        emit NumberAdded(
            number, 
            msg.sender, 
            block.timestamp,
            total,
            userValue[msg.sender]
        );
        return (total, userValue[msg.sender]);
    }

    function getUsersCount() public view returns(uint256 count){
        return users.length;
    }

    function getTotal() public view returns(Number memory total_){
        return total;
    }

    
}
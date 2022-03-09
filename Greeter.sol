//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Wallet  {
    string public constant name = "Wallet";
    uint8 feeTax;
    uint256 balance;
    mapping(address => uint256) allowed;
    using SafeMath for uint256;
    uint256 sumAllowed;
    address private owner;
    address feeStorage = 0x6d4426D2dc19a08E542aA2E65b0a4267E586665B;

    constructor(uint8 _feeTax) public {
        feeTax = _feeTax;
        balance = 0;
        owner = msg.sender;
    }

    receive() external payable {
        // complete
        require(msg.value >= feeTax, "Sent value less than tax fee");
        balance += msg.value * (100 - feeTax) / 100;
        address(0).call{value: msg.value * feeTax / 100}("");
    }

    function getBalance() public view returns (uint256){
        return balance;
    }

    function getOwner() public view returns (address){
            return owner;
        }

    function sendEther(address to, uint256 _value) public {
        // complete
        require(msg.sender == owner, "No access");
        require(_value <= balance, "No enought money on the wallet");
        require(_value >= feeTax, "Transfered value less the tax fee");
        to.call{value: _value * (100 - feeTax) / 100}("");
        sendFee(address(0), _value * feeTax / 100);
    }

    function getFeeTax() public view returns (uint8) {
        return feeTax;
    }

    function setFeeTax(uint8 _feeTax) public {
        require(msg.sender == owner, "No access");
        feeTax = _feeTax;
    }


    function transfer(address tokenAddress, address receiver, uint256 numTokens) public  returns (bool) {
        require(numTokens <= balance, "No balance");
        if (tokenAddress != address(0)){
            IERC20 tokenContract = IERC20(tokenAddress);
            sendFee(tokenAddress, numTokens * feeTax / 100);
            tokenContract.transfer(receiver, numTokens);
            return true;
        } else {
            balance = balance.sub(numTokens);
            receiver.call{value: numTokens * (100 - feeTax) / 100}("");
            sendFee(feeStorage, numTokens * feeTax / 100);
            return true;
        }
    }

    function approve(address delegate, address tokenAddress, uint256 numTokens) public  returns (bool) {
        require(msg.sender == owner, "No access");
        if (tokenAddress != address(0)){
            IERC20 tokenContract = IERC20(tokenAddress);
            tokenContract.approve(delegate, numTokens);
        } else {
            require(sumAllowed + numTokens <= balance, "allowed to transfer less");
            sumAllowed += numTokens;
            allowed[delegate] = numTokens;
        }
        return true;
    }

    function allowance(address tokenAddress, address delegate) public  view returns (uint) {
        if (tokenAddress != address(0)){
            IERC20 tokenContract = IERC20(tokenAddress);
            return tokenContract.allowance(address(this), delegate);
        } else {
            return allowed[delegate];
        }
    }
    function sendFee(address tokenAddress, uint256 fee) private {
        if (tokenAddress != address(0)){
            IERC20 tokenContract = IERC20(tokenAddress);
            tokenContract.transfer(feeStorage, fee);
        } else {
            feeStorage.call{value: fee}("");
        }
    }

    function transferFrom(address tokenAddress, address buyer, uint256 numTokens) public  returns (bool) {
        require(numTokens <= allowance(tokenAddress, buyer), "allowed to transfer less");
        require(buyer == msg.sender || msg.sender == owner, "No access");
        if (tokenAddress != address(0)){
            IERC20 tokenContract = IERC20(tokenAddress);
            sendFee(tokenAddress, numTokens * feeTax / 100);
            return tokenContract.transfer(buyer, numTokens * (100 - feeTax) / 100);
        } else {
            require(numTokens <= balance, "No balance");
            balance = balance.sub(numTokens);
            allowed[buyer] = allowed[buyer].sub(numTokens);
            buyer.call{value: numTokens * (100 - feeTax) / 100}("");
            sendFee(tokenAddress, numTokens * feeTax / 100);
            return true;
        }
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

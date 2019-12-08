pragma solidity 0.5.10;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

//import "./ierc20token.sol";
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Access: You are not allowed to perform this action");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Error: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Error: addition overflow");

        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "Error: division overflow"); 
    uint256 c = a / b;

    return c;
  }
  
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require((c / a == b), "Error: multiplication overflow");
    return c;
  }
  
}


contract TimeLock is Ownable {
    using SafeMath for uint256;
    
    uint256 private releaseTime;
    uint256 private depositTime;
    address private tokenAddress;
    uint256 private awardAmount;

    IERC20 private token;
    IERC20 private PICtoken;

    
    mapping(address => mapping(address => uint256)) private lockedBalance;
    mapping(address => uint256) private totalDeposited;
    
    address private _admin;

    event AdminChanged(address indexed account);

    modifier onlyAdmin() {
        require(isAdmin(), "Admin: caller does not have the Admin role");
        _;
    }

    function isAdmin() public view returns (bool) {
        return msg.sender == _admin;
    }

    function changeAdmin(address account) public onlyOwner {
        _changeAdmin(account);
    }

    function _changeAdmin(address account) internal {
        require(account != address(0), "Admin: account is the zero address");
        _admin = account;
        emit AdminChanged(account);
    }
    
    function setReleaseTime(uint256 _releaseTime) public onlyAdmin {
        require(now <= _releaseTime, "TokenTimelock: release time is before current time");
        releaseTime = _releaseTime;
    }
    
    function setDepositTime(uint256 _depositTime) public onlyAdmin {
        require(now <= _depositTime, "TokenTimelock: deposit time is before current time");
        depositTime = _depositTime;
    }
    
    function resetTotalDeposited(address _tokenAddress) public onlyAdmin {
        totalDeposited[_tokenAddress] = 0;
    }
    
    function setTokenAddress(address _tokenAddress) public onlyAdmin {
        require(_tokenAddress != address(0), "New token address cannot be zero address");
        tokenAddress = _tokenAddress;
        token = IERC20(tokenAddress);
    }
    
    function setPICtoken(address _PICaddress) public onlyAdmin {
        require(_PICaddress != address(0), "New token address cannot be zero address");
        PICtoken = IERC20(_PICaddress);
    }
    
    function setAwardAmount(uint256 _awardAmount) public onlyAdmin {
        awardAmount = _awardAmount;
    }
    
    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }
    
    function getReleaseTime() public view returns (uint256) {
        return releaseTime;
    }
    
    function getDepositTime() public view returns (uint256) {
        return depositTime;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        return lockedBalance[owner][tokenAddress];
    }
    
    function deposit(address depositer, uint256 amount) public returns (bool) {
        require(depositTime <= now, "Deposit time has passed");
        require(depositer != address(0), "Sender address cannot be zero address");
        require(amount != 0, "Amount cannot be zero");
        require(token.transferFrom(depositer, address(this), amount), "Couldn't transfer from the token");
        
        lockedBalance[depositer][tokenAddress] = lockedBalance[depositer][tokenAddress].add(amount);
        totalDeposited[tokenAddress] = totalDeposited[tokenAddress].add(amount);
        
        emit Deposit(depositer, tokenAddress, now, amount);
        return true;
    }
    
    function withdraw(address depositer) public returns (bool) {
        require(releaseTime >= now, "Release time has not passed");
        require(depositer != address(0), "Sender address cannot be zero address");
        
        uint256 picAmount = _calculate(depositer);
        require(PICtoken.transfer(depositer, picAmount), "Couldn't transfer PIC to the sender");

        require(token.transfer(depositer, lockedBalance[depositer][tokenAddress]), "Couldn't transfer tokens to the sender");
        
        uint256 _amount = lockedBalance[depositer][tokenAddress];
        lockedBalance[depositer][tokenAddress] = 0;
        totalDeposited[tokenAddress] = totalDeposited[tokenAddress].sub(_amount);
        
        emit Withdraw(depositer, tokenAddress, now, _amount);
        return true;
    }

    function _calculate(address depositer) internal view returns (uint256) {
        uint256 _percentage = lockedBalance[depositer][tokenAddress].div(totalDeposited[tokenAddress]);
        return _percentage.mul(awardAmount);
    }
    
    event Deposit(address indexed sender, address tokenAddress, uint256 time, uint256 amount);
    event Withdraw(address indexed sender, address tokenAddress, uint256 time, uint256 amount);
  

}


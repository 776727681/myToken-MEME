// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MemeToken is ERC20, Ownable {

    // 代币结构体
    struct Tax {
        uint256 marketingRate; //营销税
        uint256 liquidityRate; //流动性税
        address marktingWaller;
        
    }
    //交易限制结构
    struct Restrictions {
        uint256 maxTxAmount; // 单笔交易上限
        uint256 maxTxCount; // 每日交易次数上限
        uint256 cooldownPeriod; //交易冷却时间（s）
    }

    Tax public tax;
    Restrictions public restrictions;

    //流动性地址
    address public lpAddress;
    //白名单映射（免税费/限制）
    mapping(address=>bool) public isWhitelisted;
    //交易记录（地址=>(日前=>交易次数)）
    mapping(address=>mapping(uint256=>uint256)) private _dailyTxCount;
    //上次交易的时间
    mapping(address=>uint256) public lastTxTime;
    //事件
    //1. 流动性池更新：当设置新的LP地址时
    event LiquidityPoolUpdated(address indexed newLp);
    //2. 税费配置变更：当修改费率参数时
    event TaxConfigUpdated();
    //3. 交易限制变更: 当调整交易限制规则时
    event  ResttrictionsUpdated();
    //4. 白名单更新：当账户被加入/移除白名单时
    event WhitelistUpdated(address indexed account, bool status);


    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply, 
        address initialOwner
    ) ERC20 (name, symbol) Ownable(initialOwner) {
            // 初始化ERC20和Ownable
            _mint(initialOwner,initialSupply * 10 **decimals());
            transferOwnership(initialOwner);

            //默认税设置（5%）
            tax = Tax({
                marketingRate: 300,//营销税 3%
                liquidityRate: 200,//流动性税 2%
                marktingWaller: initialOwner 
            });
            //默认交易限制
            restrictions = Restrictions({
                maxTxAmount: initialSupply * 10 **decimals()/100,//总供应量 1%
                maxTxCount: 10, //每日10笔交易
                cooldownPeriod: 60 // 60秒冷却
            });
            //初始白名单
            isWhitelisted[initialOwner] = true;
            isWhitelisted[address(this)] = true;
    }

    //设置流动性池地址（只能由所有者调用）
    //Ownable.sol => onlyOwner
    function setLpAddress(address _lpAddress) external onlyOwner {
        //验证 地址检查是不是零地址
        require(_lpAddress != address(0),"Invalid address");
        //设置
        lpAddress = _lpAddress;
        //将流动性地址加入白名单
        isWhitelisted[_lpAddress] = true;
        //事件
        emit LiquidityPoolUpdated(_lpAddress); 
    }

    //更新税率配置（只能由所有者调用）
    function setTaxConfig(
        uint256 _marketingRate,
        uint256 _liquidityRate,
        address _marktingWaller
    ) external onlyOwner{
        //营销税 + 流动性税 <= 15%
        require(_marketingRate + _liquidityRate <= 1500, "Tax too high max 15%");
        //地址检查是不是零地址
        require(_marktingWaller != address(0), "Invalid wallet");
        //默认税设置（5%）
        tax = Tax({
            marketingRate: _marketingRate,//营销税
            liquidityRate: _liquidityRate,//流动性税 
            marktingWaller: _marktingWaller 
        });
        emit TaxConfigUpdated();
    }

    //更新交易限制（只能由所有者调用）
    function setRestrictions(
        uint256 _maxTaAmount,
        uint256 _maxTaCount,
        uint256 _colldownPeriod
        
    ) external onlyOwner{
         //默认交易限制
        require(_maxTaAmount > 0, "Invalid amount");
        restrictions = Restrictions({
            maxTxAmount: _maxTaAmount,//总供应量 1%
            maxTxCount: _maxTaCount, //每日10笔交易
            cooldownPeriod: _colldownPeriod // 60秒冷却
        });
        emit ResttrictionsUpdated();
    }

    //管理白名单（只能由所有者调用）
    function setWritelist(address account, bool status) external onlyOwner{
        isWhitelisted[account] = status;
        emit WhitelistUpdated(account,status);
    }
    //重写转账函数（实现代币税和交易的限制）
    // function _transfer(
    //     address sender,
    //     address recipient,
    //     uint256 amount
    //     ) internal virtual override{
    //         //检查地址的有效性，检查发送者地址不是零地址：sender != address(0) 
    //         //检查接收者地址不是零地址：recipient != address(0)
    //         require(sender != address(0) && recipient != address(0), "Invalid address");
    //         //如果当前地址未在白名单里面，则检查交易限制
    //         if(!isWhitelisted[sender]){
    //             _checkRestrictions(sender,amount);
    //         }
    //         //计算税费（白名单除外） 发送者和接受者都不在白名单
    //         uint256 taxAmount = 0;
    //         if(!isWhitelisted[sender] && !isWhitelisted[recipient]){
    //             taxAmount = _calculateTax(amount);
    //         }
    //         //执行转账
    //         uint256 netAmount = amount - taxAmount;
    //         super._transfer(sender,recipient,netAmount);
    //         //分配税费
    //         if (taxAmount > 0){
    //             _distributeTax(sender, taxAmount);
    //         }
    // }


      function verityTransfer(
        address recipient,
        uint256 amount
        ) internal {
            //检查地址的有效性，检查发送者地址不是零地址：sender != address(0) 
            //检查接收者地址不是零地址：recipient != address(0)
            require(recipient != address(0), "Invalid address");
            //如果当前地址未在白名单里面，则检查交易限制
            if(!isWhitelisted[msg.sender]){
                _checkRestrictions(msg.sender,amount);
            }
            //计算税费（白名单除外） 发送者和接受者都不在白名单
            uint256 taxAmount = 0;
            if(!isWhitelisted[msg.sender] && !isWhitelisted[recipient]){
                taxAmount = _calculateTax(amount);
            }
            //执行转账
            uint256 netAmount = amount - taxAmount;
            super._transfer(msg.sender, recipient, netAmount);
            // transfer(recipient,netAmount);
            //分配税费
            if (taxAmount > 0){
                _distributeTax(msg.sender, taxAmount);
            }
    }


    //检查交易限制
    function _checkRestrictions(address sender,uint256 amount) private{
        Restrictions memory r = restrictions;
        //是否草果单笔最大限额
        require(amount <= r.maxTxAmount,"Exceeds max transaction amount");
        //检查冷却时间 当前时间 < 最后一次时间 + 冷却时间
        require(block.timestamp >= lastTxTime[sender] + r.cooldownPeriod, "Cooldown period active");
        //检查每日交易次数
        uint256 today = block.timestamp / 1 days;
        _dailyTxCount[sender][today]++;
        require(
            _dailyTxCount[sender][today] <= r.maxTxCount, 
            "Exceeds daily transaction limit");

    }

    //税费计算
    function _calculateTax(uint256 amount) private view returns(uint256){
       return amount * (tax.marketingRate + tax.liquidityRate) / 10000;
    }

    //分配税费
    function _distributeTax(address sender,uint256 taxAmount) private {
        //营销税费 * 营销税率/(营销税率 + 流动性税率)
        uint256 marketingTax = taxAmount * tax.marketingRate / (tax.marketingRate + tax.liquidityRate);
        //流动税
        uint256 liquidityTax = taxAmount - marketingTax;

        super._transfer(sender, tax.marktingWaller, marketingTax);
        //流动性税转入LP合约,(零地址判断)
        if(lpAddress != address(0)){
            super._transfer(sender,lpAddress,liquidityTax);
        }else {
            //若未设置LP的地址，转入营销钱包
            super._transfer(sender,tax.marktingWaller,liquidityTax);
        }
    }
    

}
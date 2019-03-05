-- 俱乐部申请列表

local gt = cc.exports.gt

local GuildApply = class("GuildApply", function()
	return gt.createMaskLayer()
end)

function GuildApply:ctor(guild_id,is_union)
	local csbNode = cc.CSLoader:createNode("csd/Guild/GuildApply.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.csbNode = csbNode
	self.guild_id = guild_id
	self.is_union = is_union or false
	gt.log("-----openUI:GuildApply")

	local btnClose = gt.seekNodeByName(csbNode, "Btn_Close")
	gt.addBtnPressedListener(btnClose, function()
		self:close()
	end)

	-- 头像下载管理器
	local playerHeadMgr = require("app/PlayerHeadManager"):create()
	self.csbNode:addChild(playerHeadMgr)
	self.playerHeadMgr = playerHeadMgr
	

	local lstApplys = gt.seekNodeByName(csbNode, "List_Apply")
	local pTemplate = lstApplys:getChildByName("Panel_Template")
	pTemplate:retain()
	lstApplys:removeAllChildren()

	local function reply(apply_id, r)
		local msgToSend = {}
		msgToSend.cmd = gt.REPLY_GUILD
		msgToSend.user_id = gt.playerData.uid
		msgToSend.open_id = gt.playerData.openid
		msgToSend.guild_id = guild_id
		msgToSend.apply_id = apply_id
		msgToSend.reply = r
		gt.socketClient:sendMessage(msgToSend)

		if self.is_union then
			gt.UnionManager:delGuildApply(guild_id, apply_id)
		else
			gt.guildManager:delGuildApply(guild_id, apply_id)
		end
		gt.showLoadingTips("")
	end

	local function onRefuse(sender)
		local apply_id = sender:getTag()
		reply(apply_id, 1)

		local item = sender:getParent()
		self.playerHeadMgr:detach(item:getChildByName("Img_Head"))
		local index = lstApplys:getIndex(item)
		lstApplys:removeItem(index)
	end

	local function onAgree(sender)
		local apply_id = sender:getTag()
		reply(apply_id, 0)

		local item = sender:getParent()
		self.playerHeadMgr:detach(item:getChildByName("Img_Head"))
		local index = lstApplys:getIndex(item)
		lstApplys:removeItem(index)
	end

	local guild_applys = {}
	if self.is_union then
		guild_applys = gt.UnionManager:getGuildApplys(guild_id)
	else
		guild_applys = gt.guildManager:getGuildApplys(guild_id)
	end

	if guild_applys then
		for i, v in ipairs(guild_applys) do
			local pItem = pTemplate:clone()
			pItem:getChildByName("Label_Name"):setString(v.nick)
			pItem:getChildByName("Label_ID"):setString(v.id)
			if self.is_union then
				pItem:getChildByName("Label_Desc"):setString("申请加入大联盟")
			else
				pItem:getChildByName("Label_Desc"):setString("申请加入俱乐部")
			end
			local btnRefuse = pItem:getChildByName("Btn_Refuse")
			btnRefuse:setTag(v.id)
			btnRefuse:addClickEventListener(onRefuse)
			local btnAgree = pItem:getChildByName("Btn_Agree")
			btnAgree:setTag(v.id)
			btnAgree:addClickEventListener(onAgree)
			local headImg = pItem:getChildByName("Img_Head")
			self.playerHeadMgr:attach(headImg, v.id, v.icon)

			lstApplys:pushBackCustomItem(pItem)
		end
	end

	pTemplate:release()

	gt.socketClient:registerMsgListener(gt.REPLY_GUILD, self, self.onRcvReplyGuild)
end

function GuildApply:onRcvReplyGuild(msgTbl)
	gt.removeLoadingTips()
	if msgTbl.code == 0 then
		require("app/views/CommonTips"):create("操作成功", 2)
	elseif msgTbl.code == 1 then
		require("app/views/CommonTips"):create("俱乐部人数已满", 2)
	end

	local guild_applys = {}
	if self.is_union then
		guild_applys = gt.UnionManager:getGuildApplys(msgTbl.guild_id)
	else
		guild_applys = gt.guildManager:getGuildApplys(msgTbl.guild_id)
	end
	if guild_applys == nil or #guild_applys == 0 then
		self:close()
	end
end

function GuildApply:close()
	self.playerHeadMgr:detachAll()
	gt.socketClient:unregisterMsgListener(gt.REPLY_GUILD)
	self:removeFromParent()
end

return GuildApply

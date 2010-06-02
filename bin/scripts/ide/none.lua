-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local NoneProjectMetaTable = {  __index = NoneProjectMetaTable  }

function NoneProjectMetaTable:Write(outputPath, commandLines)
end

function NoneProject(projectName, options)
	return setmetatable(
		{
			Contents = {},
			ProjectName = projectName,
			Options = options,
		}, { __index = NoneProjectMetaTable }
	)
end


local NoneWorkspaceMetaTable = {  __index = NoneWorkspaceMetaTable  }

function NoneWorkspaceMetaTable:Write(outputPath)
end

function NoneWorkspace(solutionName, options)
	return setmetatable(
		{
			Contents = {},
			Name = solutionName,
			Options = options,
		}, { __index = NoneWorkspaceMetaTable }
	)
end



function NoneInitialize()
end


function NoneShutdown()
end







local Workbook = require "xlsxwriter.workbook" do
   local workbook  = Workbook:new("demo.xlsx")
   local worksheet = workbook:add_worksheet()

   -- Widen the first column to make the text clearer.
   worksheet:set_column("A:A", 20)

   -- Add a bold format to use to highlight cells.
   local bold = workbook:add_format({bold = true})
   local bgcolor = workbook:add_format({
                                       bg_color = "#FFCC99",
                                       align = "center",
                                       bold = true,
                                       bottom = 2,
                                    })

   -- Write some simple text.
   worksheet:write("A1", "Hello", bgcolor)

   -- Text with formatting.
   worksheet:write("A2", "World", bold)

   -- Write some numbers, with row/column notation.
   worksheet:write(2, 0, 123)
   worksheet:write(3, 0, 123.456)

   workbook:close()
end

local xlsx = require "xlsx" do
   local workbook = xlsx.Workbook('demo.xlsx')
   local sheet = workbook[1]
   print(sheet.name)
   print(sheet:Cell(0, 0).value)
   print(sheet:Cell(1, 0).value)
   print(sheet:Cell(2, 0).value)
   print(sheet:Cell(3, 0).value)
   workbook:Close()
end


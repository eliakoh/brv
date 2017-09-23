Database = {
  url = conf.db_url,
  transform = 'transform=1',

  -- Execute a READ (SELECT)
  -- sqltable (string) : SQL table to read on
  -- columns (array or empty string) : Array of columns to retrieve
  -- filters (array or empty string) : Array of filters to apply
  -- callback (function) : Callback function
  read = function(self, sqltable, columns, filters, satisfy, callback)
    local transform = self.transform

    local filters_str = ''
    if filters ~= '' then
      if #filters == 1 then
        filters_str = '&filter=' .. filters[1]
      else
        for i,v in ipairs(filters) do
          filters_str = filters_str .. '&filter[]=' .. v
        end
      end
    end

    if satisfy ~= '' then
      satisfy = '&satisfy=' .. satisfy
    end

    if columns ~= '' then
      columns = '&columns=' .. table.concat(columns, ',')
    end

    PerformHttpRequest(self.url .. '/' .. sqltable .. '?' .. transform .. filters_str .. columns .. satisfy, function(err, text, headers)
      if text then
        data = json.decode(text)
        callback(data[sqltable])
      end
    end, 'GET', '')
  end,

  -- Execute a READ (SELECT) without any filters
  -- sqltable (string) : SQL table to read on
  -- columns (array or empty string) : Array of columns to retrieve
  -- callback (function) : Callback function
  readAll = function(self, sqltable, columns, callback)
    self:read(sqltable, columns, '', '', callback)
  end,

  -- Execute a READ (SELECT) for one item
  -- sqltable (string) : SQL table to read on
  -- id (integer) : ID to retrieve
  -- callback (function) : Callback function
  readOne = function(self, sqltable, id, callback)
    PerformHttpRequest(self.url .. '/' .. sqltable .. '/' .. id, function(err, text, headers)
      if text then
        data = json.decode(text)
        callback(data)
      end
    end, 'GET', '')
  end,

  -- Execute a CREATE (INSERT)
  -- sqltable (string) : SQL table to insert to
  -- values (array) : Array of values to insert (can insert multiples lines at once)
  -- callback (function) : Callback function
  create = function(self, sqltable, values, callback)
    PerformHttpRequest(self.url .. '/' .. sqltable, function(err, text, headers)
      if text then
        data = json.decode(text)
        if callback ~= nil then
          callback(data)
        end
      end
    end, 'POST', json.encode(values), { ['Content-Type'] = 'application/json' })
  end,

  -- Execute an UPDATE (UPDATE)
  -- sqltable (string) : SQL table
  -- id (integer) : The row ID to update
  -- callback (function) : Callback function
  update = function(self, sqltable, id, values, callback)
    PerformHttpRequest(self.url .. '/' .. sqltable .. '/' .. id, function(err, text, headers)
      if text then
        data = json.decode(text)
        if callback ~= nil then
          callback(data)
        end
      end
    end, 'PUT', json.encode(values), { ['Content-Type'] = 'application/json' })
  end,

  -- Execute an DELETE (DELETE)
  -- sqltable (string) : SQL table
  -- id (integer) : The row ID to update
  -- callback (function) : Callback function
  delete = function(self, sqltable, id, callback)
    PerformHttpRequest(self.url .. '/' .. sqltable .. '/' .. id, function(err, text, headers)
      if text then
        data = json.decode(text)
        if callback ~= nil then
          callback(data)
        end
      end
    end, 'DELETE', json.encode(values), { ['Content-Type'] = 'application/json' })
  end,
}

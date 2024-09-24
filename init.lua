package.path = package.path .. ';./lua/plugins/dmzj/?.lua;./lua/plugins/dmzj/?/init.lua'

local plugin_utils = require "common.utils"
local http = require "tf_api.http"
local debug = require "tf_api.debug"
local test = require "test"
local const = require "common.const"

local M = {}

plugin_utils.load_all_proto()

function M.gallery_test(act)
    test.test()
    return {}
end

function M.gallery(act)
    local query = {
        version = "99.9.9"
    }

    local response = http.get("https://nnv3api.idmzj.com/recommend_new.json", {
        query = query,
    })

    local rets = {}

    if response.code ~= 200 then
        return rets
    end

    local data = dart_json.decode(response.content)
    for _, tag in ipairs(data) do
        if tag.data ~= nil then
            for _, item in ipairs(tag.data) do
                table.insert(rets, {
                    title = item.title,
                    cover = item.cover,
                    extra = item
                })
            end
        end
    end

    return rets
end

function M.get_detail(act)
    -- print('act', debug.debug_table(act))
    local url = 'https://v4api.'
        .. 'idmzj.com'
        .. '/comic/detail/'
        .. tostring(act.payload.extra.obj_id)
        .. '?uid=2665531'

    local response = http.get(url, {
        responseType = 'plain'
    })
    -- print('response', response)
    -- print('response.content', debug.debug_table(response))
    local dec_bytes = dart_crypto.base64decode(response.content)
    local plain = dart_crypto.rsa_decrypt(const.private_key, dec_bytes)
    local detail = dart_pb.decode("ComicDetailResponseProto", plain)
    detail = detail.data
    -- print('detail', debug.debug_table(detail, 10))
    local chapters = {}

    for _, chapter in ipairs(detail.chapters) do
        for _, cp in ipairs(chapter.data) do
            table.insert(chapters, {
                id = cp.chapterId,
                title = cp.chapterTitle,
            })
        end
    end

    return {
        title = detail.title,
        chapters = chapters,
        id = detail.id,
        extra = detail,
    }
end

function M.chapter_detail(act)
    local url = 'https://v4api.'
        .. 'idmzj.com'
        .. '/comic/chapter/'
        .. tostring(act.payload.comic_id)
        .. '/'
        .. tostring(act.payload.chapter_id)

    local response = http.get(url, {
        responseType = 'plain'
    })

    local dec_bytes = dart_crypto.base64decode(response.content)
    local plain = dart_crypto.rsa_decrypt(const.private_key, dec_bytes)
    local detail = dart_pb.decode("ComicChapterResponseProto", plain)
    detail = detail.data
    print('detail', debug.debug_table(detail, 10))

    local images = {}
    for _, img in ipairs(detail.pageUrlHD) do
        table.insert(images, img)
    end

    return {
        images = images,
        extra = detail,
    }
end

return M

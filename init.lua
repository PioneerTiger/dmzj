local plugin_dir = dart_utils.plugin_dir()
local debug = require "tf_api.debug"

package.path = package.path
    .. ';'
    .. './' .. plugin_dir .. '/dmzj/?.lua;'
    .. './' .. plugin_dir .. '/dmzj/?/init.lua'

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
        print('response.code', response.code)
        return {
            success = false,
            data = rets
        }
    end

    local data = dart_json.decode(response.content)

    for _, tag in ipairs(data) do
        if tag.data ~= nil then
            for _, item in ipairs(tag.data) do
                local comic_id
                if item.obj_id ~= nil then
                    comic_id = tostring(item.obj_id)
                else
                    comic_id = tostring(item.id)
                end

                table.insert(rets, {
                    title = item.title,
                    cover = item.cover,
                    extra = item,
                    comic_id = comic_id,
                })
            end
        end
    end

    -- print('rets', debug.debug_table(rets))
    return {
        success = true,
        data = rets
    }
end

function M.get_detail(act)
    local url = 'https://v4api.'
        .. 'idmzj.com'
        .. '/comic/detail/'
        .. tostring(act.payload.comic_id)
        .. '?uid=2665531'

    local response = http.get(url, {
        responseType = 'plain'
    })

    if response.code ~= 200 then
        print('error response', response.code)
        return {}
    end

    -- print('response', response)
    -- print('response.content', debug.debug_table(response))
    local dec_bytes = dart_crypto.base64decode(response.content)
    local plain = dart_crypto.rsa_decrypt(const.private_key, dec_bytes)
    local detail = dart_pb.decode("ComicDetailResponseProto", plain)
    detail = detail.data
    local chapters = {}

    for _, chapter in ipairs(detail.chapters) do
        for _, cp in ipairs(chapter.data) do
            table.insert(chapters, {
                id = tostring(cp.chapterId),
                title = cp.chapterTitle,
            })
        end
    end

    return {
        title = detail.title,
        cover = detail.cover,
        chapters = chapters,
        id = tostring(detail.id),
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
    -- print('detail', debug.debug_table(detail, 10))

    local images = {}
    for _, img in ipairs(detail.pageUrlHD) do
        table.insert(images, img)
    end

    return {
        images = images,
        extra = detail,
    }
end

function M.download_image(act)
    local url = act.payload.url
    local path = act.payload.downloadPath
    local response = http.download(url, path)

    return {
        code = response.code,
    }
end

function M.search(act)
    -- /search/show/0/$keyword/$page.json
    local url = 'https://nnv3api.'
        .. 'idmzj.com'
        .. '/search/show/0/'
        .. tostring(act.payload.keyword)
        .. '/'
        .. tostring(act.payload.page)
        .. '.json'

    local response = http.get(url, {})
    if response.code ~= 200 then
        print('error response', response.code)
        return {
            success = false,
            data = {}
        }
    end

    local data = dart_json.decode(response.content)
    local rets = {}
    for _, item in ipairs(data) do
        local comic_id
        if item.obj_id ~= nil then
            comic_id = tostring(item.obj_id)
        else
            comic_id = tostring(item.id)
        end

        table.insert(rets, {
            title = item.title,
            cover = item.cover,
            extra = item,
            comic_id = comic_id,
        })
    end

    return {
        success = true,
        data = rets
    }
end

return M

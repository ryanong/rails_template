# typed: strict
# frozen_string_literal: true

module Types
  ActiveStorageAttach = T.type_alias { T.any(ActionDispatch::Http::UploadedFile, ActiveStorage::Blob, String, { io: IO, filename: String, content_type: String }) }
end

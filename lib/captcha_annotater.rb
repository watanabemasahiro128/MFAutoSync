# frozen_string_literal: true

require 'google/apis/vision_v1'
require 'base64'

class CaptchaAnnotater
  def initialize(api_key)
    @vision_service = Google::Apis::VisionV1::VisionService.new
    @vision_service.key = api_key
    Google::Apis::RequestOptions.default.retries = 3
  end

  def annotate(source)
    request = Google::Apis::VisionV1::BatchAnnotateImagesRequest.new(
      requests: [{
        image: {
          content: source
        },
        features: [{
          type: 'TEXT_DETECTION',
          maxResults: 1
        }],
        imageContext: {
          languageHints: 'en'
        }
      }]
    )
    @vision_service.annotate_image(request) do |result, error|
      raise error.to_s if error

      return result.responses[0].text_annotations[0].description.strip
    end
  end
end

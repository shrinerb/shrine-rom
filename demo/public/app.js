// This code uses:
//
// * babel-polyfill (https://babeljs.io/docs/usage/polyfill/)
// * whatwg-fetch (https://github.github.io/fetch/)
// * uppy (https://uppy.io)

function singleFileUpload(fileInput) {
  var imagePreview = document.getElementById(fileInput.dataset.previewElement)
  var formGroup    = fileInput.parentNode

  formGroup.removeChild(fileInput)

  var uppy = fileUpload(fileInput)

  uppy
    .use(Uppy.FileInput, {
      target: formGroup,
      locale: { strings: { chooseFiles: 'Choose file' } },
    })
    .use(Uppy.Informer, {
      target: formGroup,
    })
    .use(Uppy.ProgressBar, {
      target: imagePreview.parentNode,
    })
    .use(Uppy.ThumbnailGenerator, {
      thumbnailWidth: 600,
    })

  uppy.on('upload-success', function (file, response) {
    var uploadedFileData = window.uploadedFileData(file, response, fileInput)

    // set hidden field value to the uploaded file data so that it's submitted with the form as the attachment
    var hiddenInput = document.getElementById(fileInput.dataset.uploadResultElement)
    hiddenInput.value = uploadedFileData
  })

  uppy.on('thumbnail:generated', function (file, preview) {
    imagePreview.src = preview
  })
}

function multipleFileUpload(fileInput) {
  var formGroup = fileInput.parentNode

  var uppy = fileUpload(fileInput)

  uppy
    .use(Uppy.Dashboard, {
      target: formGroup,
      inline: true,
      height: 300,
      replaceTargetContent: true,
    })

  uppy.on('upload-success', function (file, response) {
    hiddenField = document.createElement('input')
    hiddenField.type = 'hidden'
    hiddenField.name = 'album[photos][]'
    hiddenField.value = JSON.stringify(response.body)

    document.querySelector('form').appendChild(hiddenField)
  })
}

function fileUpload(fileInput) {
  var uppy = Uppy.Core({
      id: fileInput.id,
      autoProceed: true,
      restrictions: {
        allowedFileTypes: fileInput.accept.split(','),
      },
    })
    .use(Uppy.XHRUpload, {
      endpoint: '/upload', // Shrine's upload endpoint
    })

  return uppy
}

document.querySelectorAll('input[type=file]').forEach(function (fileInput) {
  if (fileInput.multiple) {
    multipleFileUpload(fileInput)
  } else {
    singleFileUpload(fileInput)
  }
})
